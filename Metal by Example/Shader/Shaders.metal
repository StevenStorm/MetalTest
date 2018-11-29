//
//  Shaders.metal
//  Metal by Example
//
//  Created by Local István Gulyás on 11/21/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#define lightCount 3

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
    float3 worldPosition;
    float2 texCoords;
};

struct VertexUniforms {
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
    float3x3 normalMatrix;
};

struct Light {
    float3 worldPosition;
    float3 color;
};

struct FragmentUniform {
    float3 cameraWorldPosition;
    float3 ambientLightColor;
    float3 specularColor;
    float specularPower;
    Light lights[lightCount];
};

vertex VertexOut vertex_main(VertexIn vertexIn[[stage_in]],
                             constant VertexUniforms &uniforms[[buffer(1)]]) {
    VertexOut vertexOut;
    float4 worldPosition = uniforms.modelViewMatrix * float4(vertexIn.position,1);
    vertexOut.position = uniforms.projectionMatrix * worldPosition;
    vertexOut.worldNormal = uniforms.normalMatrix * vertexIn.normal;
    vertexOut.worldPosition = worldPosition.xyz;
    vertexOut.texCoords = vertexIn.texCoords;
    return vertexOut;
}

fragment float4 fragmant_main(VertexOut fragmentIn [[stage_in]],
                              constant FragmentUniform &uniforms [[buffer(0)]],
                              texture2d<float, access::sample> baseColorTexture [[texture(0)]],
                              sampler baseColorSampler [[sampler(0)]]) {
    float3 baseColor = baseColorTexture.sample(baseColorSampler, fragmentIn.texCoords).rgb;
    float3 specularColor = uniforms.specularColor;
    float3 N = normalize(fragmentIn.worldNormal);
    float3 V = normalize(uniforms.cameraWorldPosition - fragmentIn.worldPosition);
    
    float3 finalColor(0,0,0);
    for (int index = 0; index < lightCount; index++) {
        float3 L = normalize(uniforms.lights[index].worldPosition - fragmentIn.worldPosition);
        float3 diffuseIntensity = saturate(dot(N,L));
        float3 H = normalize(L + V);
        float specularBase = saturate(dot(N, H));
        float specularIntensity = powr(specularBase, uniforms.specularPower);
        float3 lightColor = uniforms.lights[index].color;
        finalColor += uniforms.ambientLightColor * baseColor + diffuseIntensity * lightColor * baseColor + specularIntensity * lightColor * specularColor;
    }
    
    return float4(finalColor,1);
//    return float4(1,0,0,1);
}

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
