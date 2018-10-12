//
//  BufferProvider.swift
//  MetalTest
//
//  Created by Local István Gulyás on 9/19/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import Foundation
import Metal
import simd

class BufferProvider: NSObject {
    
    let inflightBuffersCount: Int
    private var uniformsBuffers: [MTLBuffer]
    private var availableBufferIndex: Int = 0
    var avaliableResourceSemaphore: DispatchSemaphore
    
    init(device: MTLDevice, inflightBuffersCount: Int, sizeOfUniformsBuffer: Int) {
        self.inflightBuffersCount = inflightBuffersCount
        uniformsBuffers = [MTLBuffer] ()
        
        for _ in 0...inflightBuffersCount-1 {
            if let uniformsBuffer = device.makeBuffer(length: sizeOfUniformsBuffer, options: []) {
                uniformsBuffers.append(uniformsBuffer)
            }
        }
        avaliableResourceSemaphore = DispatchSemaphore(value: inflightBuffersCount)
    }
    
    deinit {
        for _ in 0...self.inflightBuffersCount {
            self.avaliableResourceSemaphore.signal()
        }
    }
    
    func nextUniformsBuffer(projectionMatrix:float4x4, modelViewMatrix: float4x4, normalMatrix: float4x4, light: Light) -> MTLBuffer {
        let buffer = uniformsBuffers[availableBufferIndex]
        let bufferPointer = buffer.contents()
        let bufferSize = MemoryLayout<Float>.size*float4x4.numberOfElements()
        
        var projectionMatrix = projectionMatrix
        var modelViewMatrix = modelViewMatrix
        var normalMatrix = normalMatrix
        memcpy(bufferPointer, &modelViewMatrix, bufferSize)
        memcpy(bufferPointer + bufferSize, &projectionMatrix, bufferSize)
        memcpy(bufferPointer + 2*bufferSize, &normalMatrix, bufferSize)
        memcpy(bufferPointer + 3*bufferSize, light.raw(), Light.size())
        
        availableBufferIndex += 1
        if availableBufferIndex == inflightBuffersCount {
            availableBufferIndex = 0
        }
        
        return buffer
    }
    
}
