//
//  LightManager.swift
//  MetalTest
//
//  Created by Local István Gulyás on 9/20/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import Foundation
import Metal

struct Light {
    
    var color: (Float, Float, Float)
    var ambientIntensity: Float
    var direction: (Float, Float, Float)
    var diffuseIntensity: Float
    var shininess: Float
    var specularIntensity: Float
    
    static func size() -> Int {
        return MemoryLayout<Float>.size * 12
    }
    
    func raw() -> [Float] {
        return [color.0, color.1, color.2, ambientIntensity, direction.0, direction.1, direction.2, diffuseIntensity, shininess, specularIntensity]
    }
    
}
