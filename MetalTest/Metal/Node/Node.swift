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
    
    var postitionX: Float = 0.0
    var postitionY: Float = 0.0
    var postitionZ: Float = 0.0
    
    var rotationX: Float = 0.0
    var rotationY: Float = 0.0
    var rotationZ: Float = 0.0
    var scale: Float = 1.0
    
    var time:CFTimeInterval = 0.0
    
    private var bufferProvider: BufferProvider
    
    
    private var texture: MTLTexture?
    private lazy var samplerState: MTLSamplerState? = Node.defaultSampler(device: self.device)
    
    let light = Light(color: (1.0,1.0,1.0), ambientIntensity: 0.1, direction: (0.0, 0.0, 1.0), diffuseIntensity: 0.8, shininess: 10, specularIntensity: 2)
    
    init(name: String, vertices: [Vertex], texture: MTLTexture?, device: MTLDevice) {
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
    }
    
    func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4, clearColor: MTLClearColor ) {
        
        _ = bufferProvider.avaliableResourceSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        commandBuffer.addCompletedHandler { (_) in
            self.bufferProvider.avaliableResourceSemaphore.signal()
        }
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setCullMode(MTLCullMode.front)
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        renderEncoder?.setFragmentTexture(texture, index: 0)
        if let samplerState = samplerState {
            renderEncoder?.setFragmentSamplerState(samplerState, index: 0)
        }
        
        var nodeModelMatrix = modelMatrix()
        nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
        let uniformsBuffer = bufferProvider.nextUniformsBuffer(projectionMatrix: projectionMatrix, modelViewMatrix: nodeModelMatrix, light: light)
        renderEncoder?.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        renderEncoder?.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)
        
        
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
        renderEncoder?.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
    func modelMatrix() -> float4x4 {
        var matrix = float4x4()
        matrix.translate(postitionX, y: postitionY, z: postitionZ)
        matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
        matrix.scale(scale, y: scale, z: scale)
        return matrix
    }
    
    func updateDelta(delta: CFTimeInterval) {
        time += delta
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
