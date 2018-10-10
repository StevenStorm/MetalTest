//
//  PushMatrix.swift
//  MetalTest
//
//  Created by Local István Gulyás on 10/10/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import Foundation
import simd

struct Matrix {
    var current = float4x4()
    private var matrices = [Matrix]()
}
