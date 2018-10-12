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
    
    let name: String
    var vertexCount: Int
    var vertexBuffer: MTLBuffer?
    var bufferProvider: BufferProvider
    var texture: MTLTexture?
    var samplerState: MTLSamplerState?
    
    var matrixStack = Stack()
    
    let light: Light
    
    var update:(()->())?
    
    init(name: String, vertices: [Vertex], texture: MTLTexture?, device: MTLDevice, light: Light) {
        var vertextData = [Vertex]()
        for vertex in vertices {
            vertextData.append(vertex)
        }
        let dataSize = vertextData.count * MemoryLayout.size(ofValue: vertextData[0])
        vertexBuffer = device.makeBuffer(bytes: vertextData, length: dataSize, options: [])
        self.name = name
        vertexCount = vertices.count
        self.texture = texture
        let sizeOfUniformsBuffer = MemoryLayout<Float>.size * float4x4.numberOfElements() * 3 + Light.size()
        bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBuffer: sizeOfUniformsBuffer)
        self.light = light
        samplerState = Node.defaultSampler(device: device)
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

//Mark: matrix:

extension Node {
    
    func resetMatrixStock() {
        matrixStack = Stack()
    }
    
    func tranlate(x: Float = 0.0, y: Float = 0.0, z: Float = 0.0) {
        matrixStack.currentMatrix.model.translate(x, y: y, z: z)
    }
    
    func rotate(x: Float = 0.0, y: Float = 0.0, z: Float = 0.0) {
        matrixStack.currentMatrix.model.rotateAroundX(x, y: y, z: z)
    }
    
    func scale(scale: Float = 1.0) {
        matrixStack.currentMatrix.model.scale(scale, y: scale, z: scale)
    }
    
    func inSubMatrix(block: ()->()) {
        matrixStack.inSubMatrix {
            block()
        }
    }
    
}
