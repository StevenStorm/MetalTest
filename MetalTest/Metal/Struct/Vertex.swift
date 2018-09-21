//
//  Vertex.swift
//  MetalTest
//
//  Created by Local István Gulyás on 9/20/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import Foundation

struct Vertex {
    
    var x,y,z: Float
    var r,g,b,a: Float
    var s,t: Float
    var nX, nY, nZ: Float
    
    func floatBuffer() -> [Float] {
        return [x,y,z,r,g,b,a,s,t,nX,nY,nZ]
    }
    
}
