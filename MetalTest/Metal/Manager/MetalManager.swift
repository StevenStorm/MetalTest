//
//  MetalManager.swift
//  MetalTest
//
//  Created by Local István Gulyás on 9/18/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import UIKit
import MetalKit
import simd

class MetalManager: NSObject {
    
    private var device: MTLDevice
    private var pipelineState: MTLRenderPipelineState!
    private var defaultLibrary: MTLLibrary?
    private let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    private var commandQueue: MTLCommandQueue?
    private var projectionMatrix = float4x4()
    private var worldModelMatrix = float4x4()
    
    private let panSensitivity: Float = 5.0
    private var lastPanLocation: CGPoint!
    
    private var bufferProvider: BufferProvider
    private var depthStencilState: MTLDepthStencilState?
    private var depthTexture: MTLTexture?
    private var nodeArray = [Node]()
    
    private var panGestX: Float = 0.0
    private var panGestY: Float = 0.0
    private var panGestXDelta: Float = 0.0
    private var panGestYDelta: Float = 0.0
    
    private var light = Light(color: (1.0,1.0,1.0), ambientIntensity: 0.1, direction: (0.0, 0.0, 1.0), diffuseIntensity: 0.8, shininess: 10, specularIntensity: 2)
    
    weak var view: MTKView? {
        didSet {
            view?.delegate = self
            view?.preferredFramesPerSecond = 60
            view?.clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0)
            view?.device = device
            view?.depthStencilPixelFormat = .depth32Float_stencil8
            setupProjectionMatrix()
            guard let size = view?.drawableSize else { return }
            let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float_stencil8, width: Int(size.width), height: Int(size.height), mipmapped: false)
            desc.storageMode = .private
            desc.usage = .renderTarget
            depthTexture = device.makeTexture(descriptor: desc)
            depthTexture?.label = "DepthStencil"
        }
    }
    
    private var textureLoader: MTKTextureLoader
    
    init(device: MTLDevice) {
        self.device = device
        self.textureLoader = MTKTextureLoader(device: device)
        defaultLibrary = device.makeDefaultLibrary()
        worldModelMatrix.translate(0.0, y: 0.0, z: -7.0)
        worldModelMatrix.rotateAroundX(float4x4.degrees(toRad: 45), y: 0.0, z: 0.0)
        let sizeOfUniformsBuffer = MemoryLayout<Float>.size * float4x4.numberOfElements() * 2 + Light.size()
        bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBuffer: sizeOfUniformsBuffer)
        
        super.init()
        
        setupDepthStencilState()
    }
    
    private func setupProjectionMatrix() {
        guard let view = self.view else { return }
        projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85), aspectRatio: Float(view.bounds.width/view.bounds.height), nearZ: 0.01, farZ: 100.0)
    }
    
    func createNode() {
        guard let commandQueue = commandQueue else {
            return
        }
//        let rotationCube = Cube(device: device, commandQ: commandQueue, textureLoader: textureLoader, light: light)
//        rotationCube.translate(xDelta: 0.0, yDelta: 0.0, zDelta: -4.0)
////        rotationCube.movement = { [unowned self] in
////            rotationCube.rotate(xDelta: -self.panGestYDelta)
////            rotationCube.rotate(yDelta: -self.panGestXDelta)
////        }
//        nodeArray.append(rotationCube)
        let movementCube = Cube(device: device, commandQ: commandQueue, textureLoader: textureLoader, light: light)
        movementCube.update = {
            movementCube.pushMatrix()
            movementCube.rotate(yDelta: 0.01)
            movementCube.rotate(xDelta: 0.01)
            movementCube.popMatrix()
        }
        movementCube.movement = { [unowned self] in
            movementCube.translate(zDelta: -self.panGestYDelta)
            movementCube.translate(xDelta: -self.panGestXDelta)
        }
        nodeArray.append(movementCube)
        setupGesture()
    }
    
    private func loadFragmentProgram(programName: String) {
        pipelineStateDescriptor.fragmentFunction = defaultLibrary?.makeFunction(name: programName)
    }
    
    private func loadVertexProgram(programName: String) {
        pipelineStateDescriptor.vertexFunction = defaultLibrary?.makeFunction(name: programName)
    }
    
    func createRenderPipeLine() {
        loadFragmentProgram(programName: "basic_fragment")
        loadVertexProgram(programName: "basic_vertex")
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        if let view = self.view {
            pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        }
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            print("Can't make renderPipelineState object")
        }
    }
    
    private func setupDepthStencilState() {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = MTLCompareFunction.less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = self.device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    func createCommandQueue() {
        commandQueue = device.makeCommandQueue()
    }
    
    func render(drawable: CAMetalDrawable?) {
        guard let drawable = drawable, let commandBuffer = self.commandQueue?.makeCommandBuffer() else {
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
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        renderPassDescriptor.depthAttachment.loadAction = .clear
        
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        renderEncoder.setCullMode(MTLCullMode.front)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        nodeArray.forEach { (node) in
            node.update?()
            node.render(commandBuffer: commandBuffer, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, renderEncoder: renderEncoder)
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
    private func setupGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(MetalManager.pan))
        view?.addGestureRecognizer(pan)
    }
    
    @objc private func pan(panGesture: UIPanGestureRecognizer) {
        guard let view = self.view else {
            return
        }
        let pointInView = panGesture.location(in: view)
        if panGesture.state == UIGestureRecognizer.State.changed {
            let xDelta = Float((lastPanLocation.x - pointInView.x) / view.bounds.width) * panSensitivity
            let yDelta = Float((lastPanLocation.y - pointInView.y) / view.bounds.width) * panSensitivity
            panGestXDelta = xDelta
            panGestYDelta = yDelta
            nodeArray.forEach { (node) in
                node.movement?()
            }
        }
        lastPanLocation = pointInView
    }
    
}

extension MetalManager: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85), aspectRatio: Float(view.bounds.width/view.bounds.height), nearZ: 0.01, farZ: 100.0)
    }
    
    func draw(in view: MTKView) {
        render(drawable: view.currentDrawable)
    }
    
}
