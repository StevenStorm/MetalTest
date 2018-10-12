//
//  RenderManager.swift
//  MetalTest
//
//  Created by Local István Gulyás on 10/11/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import Foundation
import MetalKit
import simd

class RenderManager {
    
    private var commandQueue: MTLCommandQueue
    private var depthTexture: MTLTexture
    private var bufferProvider: BufferProvider
    private var depthStencilState: MTLDepthStencilState
    private var pipelineState: MTLRenderPipelineState
    private var nodeArray = [Node]()
    private var worldModelMatrix = float4x4()
    
    static func build(view:MTKView, device: MTLDevice, commandQueue: MTLCommandQueue) -> RenderManager? {
        guard let pipelineState = createPipelineState(view: view, device: device) else { return nil }
        guard let depthTexture = createDepthTextureFromMTKView(view.drawableSize, on: device) else { return nil }
        guard let depthStencilState = createDepthStencilStateOnDevice(device) else { return nil }
        let worldModelMatrix = createWorldMatrixModel()
        let sizeOfUniformsBuffer = MemoryLayout<Float>.size * float4x4.numberOfElements() * 2 + Light.size()
        let bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBuffer: sizeOfUniformsBuffer)
        return RenderManager(commandQueue: commandQueue, bufferProvider: bufferProvider, pipelineState: pipelineState, depthTexture: depthTexture, depthStencilState: depthStencilState, worldModelMatrix: worldModelMatrix)
    }
    
    static private func createPipelineState(view:MTKView, device: MTLDevice) -> MTLRenderPipelineState? {
        guard let defaultLibrary = device.makeDefaultLibrary() else { return nil }
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "basic_fragment")
        pipelineStateDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "basic_vertex")
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        do {
            return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            print("Can't make renderPipelineState object")
            return nil
        }
    }
    
    static private func createDepthTextureFromMTKView(_ drawableSize: CGSize, on device: MTLDevice) -> MTLTexture? {
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float_stencil8, width: Int(drawableSize.width), height: Int(drawableSize.height), mipmapped: false)
        desc.storageMode = .private
        desc.usage = .renderTarget
        let depthTexture = device.makeTexture(descriptor: desc)
        depthTexture?.label = "DepthStencil"
        return depthTexture
    }
    
    static private func createDepthStencilStateOnDevice(_ device: MTLDevice) -> MTLDepthStencilState? {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = MTLCompareFunction.less
        depthStencilDescriptor.isDepthWriteEnabled = true
        return device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    static func createWorldMatrixModel() -> float4x4 {
        var worldModelMatrix = float4x4()
        worldModelMatrix.translate(0.0, y: 0.0, z: -7.0)
        worldModelMatrix.rotateAroundX(float4x4.degrees(toRad: 45), y: 0.0, z: 0.0)
        return worldModelMatrix
    }
    
    private init(commandQueue: MTLCommandQueue,
         bufferProvider: BufferProvider,
         pipelineState: MTLRenderPipelineState,
         depthTexture: MTLTexture,
         depthStencilState: MTLDepthStencilState, worldModelMatrix: float4x4) {
        
        self.commandQueue = commandQueue
        self.bufferProvider = bufferProvider
        self.pipelineState = pipelineState
        self.depthTexture = depthTexture
        self.depthStencilState = depthStencilState
        self.worldModelMatrix = worldModelMatrix
    }
    
    func refreshDepthTexture(drawableSize: CGSize, device: MTLDevice) {
        depthTexture = RenderManager.createDepthTextureFromMTKView(drawableSize, on: device) ?? depthTexture
    }
    
    func runMovementBlock() {
        nodeArray.forEach { (node) in
            node.movement?()
        }
    }
    
    func addNode(_ node: Node) {
        nodeArray.append(node)
    }
    
    func render(drawable: CAMetalDrawable, projectionMatrix: float4x4) {
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        commandBuffer.addCompletedHandler { (_) in
            self.bufferProvider.avaliableResourceSemaphore.signal()
        }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        renderPassDescriptor.depthAttachment.texture = depthTexture
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        renderPassDescriptor.depthAttachment.storeAction = .store
        renderPassDescriptor.depthAttachment.loadAction = .clear
        
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        renderEncoder.setCullMode(MTLCullMode.front)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        nodeArray.forEach { (node) in
            node.update?()
            render(node: node, commandBuffer: commandBuffer, drawable: drawable, projectionMatrix: projectionMatrix, renderEncoder: renderEncoder)
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func render(node: Node, commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable, projectionMatrix: float4x4, renderEncoder: MTLRenderCommandEncoder ) {
        
        renderEncoder.setVertexBuffer(node.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(node.texture, index: 0)
        if let samplerState = node.samplerState {
            renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        }
        var nodeModelMatrix = node.matrixStack.currentMatrix.modelMatrix()
        nodeModelMatrix.multiplyLeft(worldModelMatrix)
        let normalMatrix = simd_transpose(simd_inverse(nodeModelMatrix))
        let uniformsBuffer = node.bufferProvider.nextUniformsBuffer(projectionMatrix: projectionMatrix, modelViewMatrix: nodeModelMatrix, normalMatrix: normalMatrix, light: node.light)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: node.vertexCount, instanceCount: node.vertexCount/3)
        node.resetMatrixStock()
    }
    
    
    
}
