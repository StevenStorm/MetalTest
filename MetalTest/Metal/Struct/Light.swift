//
//  LightManager.swift
//  MetalTest
//
//  Created by Local István Gulyás on 9/20/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import Foundation
import Metal
import simd

struct Light {
    
    var color: float3
    var ambientIntensity: Float
    var postition: float4
    private var _direction: float3
    var direction: float3 {
        get {
            let direction = (worldMatrix * float4(_direction, 0)).xyz
            return simd_normalize(direction)
        }
        set {
            _direction = newValue
        }
    }
    var diffuseIntensity: Float
    var shininess: Float
    var specularIntensity: Float
    var worldMatrix = float4x4()
    
    static func size() -> Int {
        return MemoryLayout<Float>.size * 16
    }
    
    init(color: float3, ambientIntensity: Float, position: float4, direction: float3, diffuseIntensity: Float, shininess: Float, specularIntensity: Float) {
        self.color = color
        self.ambientIntensity = ambientIntensity
        self.postition = position
        self.diffuseIntensity = diffuseIntensity
        self.shininess = shininess
        self.specularIntensity = specularIntensity
        self._direction = direction
    }
    
    func raw() -> [Float] {
        return [color.x, color.y, color.z, ambientIntensity, postition.x, postition.y, postition.z, postition.w, direction.x, direction.y, direction.z, diffuseIntensity, shininess, specularIntensity]
    }
    
}
