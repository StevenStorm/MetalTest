//
//  Render.swift
//  Metal by Example
//
//  Created by Local István Gulyás on 11/21/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import Foundation
import MetalKit
import ModelIO
import simd

struct VertexUniforms {
    var modelMatrix: float4x4
    var viewProjectionMatrix: float4x4
    var normalMatrix: float3x3
}

struct FragmentUniforms {
    var cameraWorldPosition = float3(0,0,0)
    var ambientLight = float3(0,0,0)
    var specularColor = float3(1,1,1)
    var specularPower = Float(1)
    var light0 = Light()
    var light1 = Light()
    var light2 = Light()
}

class Renderer: NSObject, MTKViewDelegate {
    
    static let vertexFunctionName = "vertex_main"
    static let fragmentFunctionName = "fragmant_main"
    static let depthEnable = true
    static let fishCount = 10
    
    let device: MTLDevice
    let mtkView: MTKView
    
    lazy var samplerState: MTLSamplerState = Renderer.buildSamplerState(device: device)
    lazy var rendererPipeLine = Renderer.buildPiplineWith(device: device, mtkView: mtkView, vertexDescriptor: vertexDescriptor)
    lazy var depthStencilState = Renderer.buildDepthStencilStateWith(device: device)
    lazy var vertexDescriptor = Renderer.buildVertexDescriptor()
    lazy var scene = Renderer.buildScene(device: device, vertexDescriptor: vertexDescriptor)
    lazy var commandQueue: MTLCommandQueue = {
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Could not create command queue")
        }
        return commandQueue
    }()
    
    var meshes: [MTKMesh] = []
    var baseColorTexture: MTLTexture?
    
    var time: Float = 0
    var cameraWorldPosition = float3(0,0,4)
    var viewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
    
    init(device: MTLDevice, mtkView: MTKView) {
        self.device = device
        self.mtkView = mtkView
    }
    
    static func buildPiplineWith(device: MTLDevice, mtkView: MTKView, vertexDescriptor: MDLVertexDescriptor) -> MTLRenderPipelineState {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not create default Library")
        }
        let vertexFunction = library.makeFunction(name: Renderer.vertexFunctionName)
        let fragmentFunction = library.makeFunction(name: Renderer.fragmentFunctionName)
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        guard let metalVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor) else {
            fatalError("Couldn't create model descriptor")
        }
        pipelineDescriptor.vertexDescriptor = metalVertexDescriptor
        do {
            return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create Render pipeline state object: \(error)")
        }
    }
    
    static func buildDepthStencilStateWith(device: MTLDevice) -> MTLDepthStencilState {
        let depthStencilStateDescriptor = MTLDepthStencilDescriptor()
        depthStencilStateDescriptor.depthCompareFunction = .less
        depthStencilStateDescriptor.isDepthWriteEnabled = Renderer.depthEnable
        guard let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilStateDescriptor) else {
            fatalError("Could not create Depth Stencil State")
        }
        return depthStencilState
    }
    
    static func buildSamplerState(device: MTLDevice) -> MTLSamplerState {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        guard let samplerState = device.makeSamplerState(descriptor: samplerDescriptor) else {
            fatalError("Could not create samplreState")
        }
        return samplerState
    }
    
    static func buildVertexDescriptor() -> MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size*3, bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size*6, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size*8)
        return vertexDescriptor
    }
    
    static func buildScene(device: MTLDevice, vertexDescriptor: MDLVertexDescriptor) -> Scene {
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let textureLoader = MTKTextureLoader(device: device)
        let scene = Scene()
        scene.ambientLightColor = float3(0.01,0.01,0.01)
        let light0 = Light(worldPosition: float3(2,2,2), color: float3(1,1,1))
        let light1 = Light(worldPosition: float3(-2,2,2), color: float3(1,1,1))
        let light2 = Light(worldPosition: float3(0,-2,2), color: float3(1,1,1))
        scene.lights = [light0, light1, light2]
        let bob = Node(name: "bob")
        bob.model.loadModelWithName("bob", device: device, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        bob.material.loadTextureWithName("bob_baseColor", textureLoader: textureLoader)
        bob.material.specularPower = 100
        bob.material.specularColor = float3(0.8,0.8,0.8)
        scene.rootNode.children.append(bob)
        
        let blubModel = Model()
        blubModel.loadModelWithName("blub", device: device, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        let blubMaterial = Material()
        blubMaterial.loadTextureWithName("blub_baseColor", textureLoader: textureLoader)
        blubMaterial.specularColor = float3(0.8,0.8,0.8)
        blubMaterial.specularPower = 40
        for index in 1...Renderer.fishCount {
            let blub = Node(name: "blub \(index)")
            blub.model = blubModel
            blub.material = blubMaterial
            scene.rootNode.children.append(blub)
        }
        
        return scene
    }
    
    func update(_ view:MTKView) {
        time += 1/Float(view.preferredFramesPerSecond)
        cameraWorldPosition = float3(0,0,4)
        viewMatrix = float4x4(translationBy: -cameraWorldPosition)
        let aspectRatio = Float(view.drawableSize.width/view.drawableSize.height)
        projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi/5, aspectRatio: aspectRatio, nearZ: 0.1, farZ: 100)
        let angle = -time
        scene.rootNode.modelMatrix = float4x4(rotationAbout: float3(0,1,0), by: angle) * float4x4(scaleBy: 1.5)
        
        if let bob = scene.nodeName("bob") {
            bob.modelMatrix = float4x4(translationBy: float3(0,0.15*sin(time),0))
        }
        
        let blubBaseTransform = float4x4(rotationAbout: float3(0,0,1), by: -.pi/2) * float4x4(scaleBy: 0.25) * float4x4(rotationAbout: float3(0,1,0), by: -.pi/2)
        
        for index in 1...Renderer.fishCount {
            if let blub = scene.nodeName("blub \(index)") {
                let pivotPosition = float3(0.8,0,0)
                let rotationOffSet = float3(0.8,0,0)
                let rotationSpeed = Float(0.3)
                let horizontalAngle = 2 * Float.pi / Float(Renderer.fishCount) * Float(index - 1)
                let rotationAngle = 2 * Float.pi * Float(rotationSpeed * time) + horizontalAngle
                blub.modelMatrix = float4x4(rotationAbout: float3(0,1,0), by: horizontalAngle) * float4x4(translationBy: rotationOffSet) * float4x4(rotationAbout: float3(0,0,1), by: rotationAngle) * float4x4(translationBy: pivotPosition) * blubBaseTransform
            }
        }
        
    }
    
    func drawNodeRecursive(_ node: Node, parentTransform: float4x4, commandEncoder: MTLRenderCommandEncoder) {
        let modelMatrix = parentTransform * node.modelMatrix
        
        if let mesh = node.model.mesh, let baseColorTexture = node.material.baseColorTexture, let vertexBuffer = mesh.vertexBuffers.first {
            let viewPojectionMatrix = projectionMatrix * viewMatrix
            var vertexUniforms = VertexUniforms(modelMatrix: modelMatrix, viewProjectionMatrix: viewPojectionMatrix, normalMatrix: modelMatrix.normalMatrix)
            commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<VertexUniforms>.size, index: 1)
            var fragmentUniforms = FragmentUniforms(cameraWorldPosition: cameraWorldPosition,
                                                    ambientLight: scene.ambientLightColor,
                                                    specularColor: node.material.specularColor,
                                                    specularPower: node.material.specularPower,
                                                    light0: scene.lights[0],
                                                    light1: scene.lights[1],
                                                    light2: scene.lights[2])
            commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)
            commandEncoder.setFragmentTexture(baseColorTexture, index: 0)
            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
            for subMesh in mesh.submeshes {
                let indexBuffer = subMesh.indexBuffer
                commandEncoder.drawIndexedPrimitives(type: subMesh.primitiveType,
                                                     indexCount: subMesh.indexCount,
                                                     indexType: subMesh.indexType,
                                                     indexBuffer: indexBuffer.buffer,
                                                     indexBufferOffset: indexBuffer.offset)
            }
        }
        
        for child in node.children {
            drawNodeRecursive(child, parentTransform: modelMatrix, commandEncoder: commandEncoder)
        }
    }
    
    //MARK: MTKViewDelegate -
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        update(view)
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setRenderPipelineState(rendererPipeLine)
        commandEncoder.setFragmentTexture(baseColorTexture, index: 0)
        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        drawNodeRecursive(scene.rootNode, parentTransform: matrix_identity_float4x4, commandEncoder: commandEncoder)
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
}
