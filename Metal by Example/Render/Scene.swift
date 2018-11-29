//
//  Scene.swift
//  Metal by Example
//
//  Created by Local István Gulyás on 11/26/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import MetalKit
import simd

struct Light {
    var worldPosition = float3(0, 0, 0)
    var color = float3(0, 0, 0)
}

class Material {
    var specularColor = float3(1,1,1)
    var specularPower = Float(1)
    var baseColorTexture: MTLTexture?
    
    func loadTextureWithName(_ name: String, textureLoader: MTKTextureLoader, options: [MTKTextureLoader.Option:Any] = [.generateMipmaps: true, .SRGB: true]) {
        baseColorTexture = try? textureLoader.newTexture(name: name, scaleFactor: 1.0, bundle: Optional.none, options: options)
    }
}

class Model {
    
    var mesh: MTKMesh?
    
    func loadModelWithName(_ name: String, device:MTLDevice, vertexDescriptor: MDLVertexDescriptor, bufferAllocator: MTKMeshBufferAllocator) {
        let modelURL = Bundle.main.url(forResource: name, withExtension: "obj")
        let asset = MDLAsset(url: modelURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        do {
            mesh = try MTKMesh.newMeshes(asset: asset, device: device).metalKitMeshes.first
        } catch {
            fatalError("Could not extract Meshes from model I/O: \(error)")
        }
    }
    
}

class Node {
    var name: String
    weak var parent: Node?
    var children = [Node]()
    var modelMatrix = matrix_identity_float4x4
    var model = Model()
    var material = Material()
    
    init(name: String) {
        self.name = name
    }
    
    func nodeNameRecursive(_ name: String) -> Node? {
        for node in children {
            if node.name == name {
                return node
            } else if let matchingGrandChildren = node.nodeNameRecursive(name) {
                return matchingGrandChildren
            }
        }
        return Optional.none
    }
    
    
}

class Scene {
    var rootNode = Node(name: "Root")
    var ambientLightColor = float3(0,0,0)
    var light0 = Light()
    var light1 = Light()
    var light2 = Light()
    var skyMap = Node(name:"Skymap")
    
    func nodeName(_ name: String) -> Node? {
        if rootNode.name == name {
            return rootNode
        } else {
            return rootNode.nodeNameRecursive(name)
        }
    }
    
    func setSkyMap(device: MTLDevice) {
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let sphereMDLMesh = MDLMesh.newEllipsoid(withRadii: float3(150,150,150),
                                                   radialSegments: 20,
                                                   verticalSegments: 20,
                                                   geometryType: .triangles,
                                                   inwardNormals: false,
                                                   hemisphere: false,
                                                   allocator: bufferAllocator)
        do {
            skyMap.model.mesh = try MTKMesh(mesh: sphereMDLMesh, device: device)
        } catch {
            fatalError("Could not extract Meshes from model I/O: \(error)")
        }
    }
    
}

