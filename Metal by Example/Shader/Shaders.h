//
//  Shaders.h
//  Metal by Example
//
//  Created by Local István Gulyás on 11/29/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

#ifndef Shaders_h
#define Shaders_h

#import <simd/simd.h>

typedef struct
{
    matrix_float4x4 modelViewMatrix;
    matrix_float4x4 projectionMatrix;
    matrix_float3x3 normalMatrix;
    
} VertexUniforms;
#endif /* Shaders_h */
