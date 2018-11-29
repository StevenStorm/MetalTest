//
//  SkyboxShaders.metal
//  Metal by Example
//
//  Created by Local István Gulyás on 11/29/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "Shaders.h"

struct SkyBoxVertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct SkyBoxVertexOut {
    float4 position [[position]];
    float3 texCoords;
};

vertex SkyBoxVertexOut skybox_vertex(SkyBoxVertexIn skyboxIn[[stage_in]],
                                     constant VertexUniforms &uniforms[[buffer(1)]]) {
    SkyBoxVertexOut skyboxOut;
    skyboxOut.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(skyboxIn.position,1);
    skyboxOut.texCoords = skyboxIn.normal;
    return skyboxOut;
}

fragment float4 skybox_fragment(SkyBoxVertexOut fragmentIn [[stage_in]],
                                texturecube<float> skybox_texture [[texture(0)]]) {
    constexpr sampler linearSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
    
    float4 color = skybox_texture.sample(linearSampler, fragmentIn.texCoords);
    
    return color;
}
