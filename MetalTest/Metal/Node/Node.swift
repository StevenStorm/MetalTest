//
//  Node.swift
//  MetalTest
//
//  Created by Local István Gulyás on 9/18/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import UIKit
import Metal
import simd

class Node {
    
    private let device: MTLDevice
    private let name: String
    private var vertexCount: Int
    private var vertexBuffer: MTLBuffer?
    private var bufferProvider: BufferProvider
    private var texture: MTLTexture?
    private lazy var samplerState: MTLSamplerState? = Node.defaultSampler(device: self.device)
    
    private var matrixStack = Stack()
//    private var testMatrix = float4x4()
    
    var time:CFTimeInterval = 0.0
    let light: Light
    
    var update:(()->())?
    var movement:(()->())?
    
    init(name: String, vertices: [Vertex], texture: MTLTexture?, device: MTLDevice, light: Light) {
        var vertextData = [Vertex]()
        for vertex in vertices {
            vertextData.append(vertex)
        }
        
        let dataSize = vertextData.count * MemoryLayout.size(ofValue: vertextData[0])
        vertexBuffer = device.makeBuffer(bytes: vertextData, length: dataSize, options: [])
        
        self.name = name
        self.device = device
        vertexCount = vertices.count
        self.texture = texture
        
        let sizeOfUniformsBuffer = MemoryLayout<Float>.size * float4x4.numberOfElements() * 2 + Light.size()
        bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBuffer: sizeOfUniformsBuffer)
        self.light = light
    }
    
    func render(commandBuffer: MTLCommandBuffer, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4, renderEncoder: MTLRenderCommandEncoder ) {
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)
        if let samplerState = samplerState {
            renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        }
        var nodeModelMatrix = matrixStack.currentMatrix.modelMatrix()
        nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
        let uniformsBuffer = bufferProvider.nextUniformsBuffer(projectionMatrix: projectionMatrix, modelViewMatrix: nodeModelMatrix, light: light)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
    }
    
    func updateDelta(delta: CFTimeInterval) {
        time += delta
        update?()
    }
    
}

//MARK: texture

extension Node {
    
    class func defaultSampler(device: MTLDevice) -> MTLSamplerState? {
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter = MTLSamplerMinMagFilter.nearest
        sampler.magFilter = MTLSamplerMinMagFilter.nearest
        sampler.mipFilter = MTLSamplerMipFilter.nearest
        sampler.maxAnisotropy = 1
        sampler.sAddressMode = MTLSamplerAddressMode.clampToEdge
        sampler.tAddressMode = MTLSamplerAddressMode.clampToEdge
        sampler.rAddressMode = MTLSamplerAddressMode.clampToEdge
        sampler.normalizedCoordinates = true
        sampler.lodMinClamp = 0
        sampler.lodMaxClamp = .greatestFiniteMagnitude
        return device.makeSamplerState(descriptor: sampler)
    }
    
}

//Mark: movement:

extension Node {
    
    func rotate(xDelta: Float = 0.0, yDelta: Float = 0.0, zDelta: Float = 0.0) {
        matrixStack.currentMatrix.model.rotateAroundX(xDelta, y: yDelta, z: zDelta)
    }
    
    func translate(xDelta: Float = 0.0, yDelta: Float = 0.0, zDelta: Float = 0.0) {
        matrixStack.currentMatrix.model.translate(xDelta, y: yDelta, z: zDelta)
    }
    
    func scale(_ scale: Float) {
        matrixStack.currentMatrix.model.scale(scale, y: scale, z: scale)
    }
    
    func pushMatrix() {
        matrixStack.push()
    }
    
    func popMatrix() {
        matrixStack.pop()
    }
    
}
