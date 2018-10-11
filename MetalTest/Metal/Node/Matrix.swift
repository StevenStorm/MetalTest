//
//  PushMatrix.swift
//  MetalTest
//
//  Created by Local István Gulyás on 10/10/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import Foundation
import simd

class Matrix {
    
    var model = float4x4()
    var matrices = [Matrix]()
    var owner: Matrix?

    func modelMatrix() -> float4x4 {
        if matrices.count == 0 {
            return model
        } else {
            let models = matrices.map({ $0.modelMatrix() })
            let childModel = models.reduce(float4x4(),{$0 * $1})
            return model * childModel
        }
    }
}

class Stack {
    var currentMatrix = Matrix()
    private var matrices = [Matrix()]
    
    func push() {
        let newMatrix = Matrix()
        newMatrix.owner = currentMatrix
        currentMatrix.matrices.append(newMatrix)
        currentMatrix = newMatrix
    }
    
    func pop() {
        guard let current = currentMatrix.owner else { return }
        currentMatrix = current
    }
    
}
