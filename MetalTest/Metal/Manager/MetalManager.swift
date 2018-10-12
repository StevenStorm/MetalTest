//
//  MetalManager.swift
//  MetalTest
//
//  Created by Local István Gulyás on 9/18/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import UIKit
import MetalKit
import simd

class MetalManager: NSObject {
    
    private var device: MTLDevice
    private var commandQueue: MTLCommandQueue
    private var projectionMatrix = float4x4()
    private var renderManager: RenderManager
    private var textureLoader: MTKTextureLoader
    weak var view: MTKView! {
        didSet {
            setView()
        }
    }
    
    static func buildMetalManager(view:MTKView) -> MetalManager? {
        view.depthStencilPixelFormat = .depth32Float_stencil8
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        guard let commandQueue = device.makeCommandQueue() else { return nil }
        guard let renderManager = RenderManager.build(view: view, device: device, commandQueue: commandQueue) else { return nil }
        return MetalManager(device: device,
                                        commandQueue: commandQueue,
                                        view: view,
                                        renderManager: renderManager)
    }
    
    init(device: MTLDevice,
         commandQueue: MTLCommandQueue,
         view: MTKView,
         renderManager: RenderManager) {
        
        self.device = device
        self.commandQueue = commandQueue
        self.textureLoader = MTKTextureLoader(device: device)
        self.view = view
        self.renderManager = renderManager
        super.init()
        self.setView()
    }
    
    private func setView() {
        view.delegate = self
        view.preferredFramesPerSecond = 60
        view.clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0)
        view.device = device
        view.depthStencilPixelFormat = .depth32Float_stencil8
        setupProjectionMatrix()
        renderManager.refreshDepthTexture(drawableSize: view.drawableSize, device: device)
    }
    
    private func setupProjectionMatrix() {
        projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85), aspectRatio: Float(view.bounds.width/view.bounds.height), nearZ: 0.01, farZ: 100.0)
    }
    
    func createNode(name: String, vertices: [Vertex], textureImage: UIImage?, light: Light) -> Node {
        
        var texture: MTLTexture? = nil
        if let image = textureImage?.cgImage {
            texture = try! textureLoader.newTexture(cgImage: image, options: [MTKTextureLoader.Option.SRGB:(false as NSNumber)])
        }
        return Node(name: name, vertices: vertices, texture: texture, device: device, light: light)
    }
    
    func addNode(_ node: Node) {
        renderManager.addNode(node)
    }
    
}

extension MetalManager: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85), aspectRatio: Float(size.width/size.height), nearZ: 0.01, farZ: 100.0)
        renderManager.refreshDepthTexture(drawableSize: size, device: device)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else { return }
        renderManager.render(drawable: drawable, projectionMatrix: projectionMatrix)
    }
    
}
