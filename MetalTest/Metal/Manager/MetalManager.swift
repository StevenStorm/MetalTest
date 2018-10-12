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
    
    private let panSensitivity: Float = 5.0
    private var lastPanLocation: CGPoint!
    
    private var panGestX: Float = 0.0
    private var panGestY: Float = 0.0
    private var panGestXDelta: Float = 0.0
    private var panGestYDelta: Float = 0.0
    
    private var renderManager: RenderManager
    
    private var light = Light(color: (1.0,1.0,1.0), ambientIntensity: 0.1, direction: (0.0, 0.0, 1.0), diffuseIntensity: 0.8, shininess: 10, specularIntensity: 2)
    
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
    
    func createNode() {
        let rotationCube = Cube(device: device, commandQ: commandQueue, textureLoader: textureLoader, light: light)
        var basicTranslateZ: Float = 0.0
        var basicTranslateX: Float = 0.0
        var rotation: Float = 0.0
        rotationCube.update = {
            basicTranslateZ -= self.panGestYDelta
            basicTranslateX -= self.panGestXDelta
            rotationCube.tranlate(z: basicTranslateZ)
            rotationCube.tranlate(x: basicTranslateX)
            rotationCube.scale(scale: 0.1)
            rotationCube.inSubMatrix {
                rotation += 0.01
                rotationCube.rotate(y: rotation)
            }
        }
        renderManager.addNode(rotationCube)
        let movementCube = Cube(device: device, commandQ: commandQueue, textureLoader: textureLoader, light: light)
        var orbitalRotationY: Float = 0.0
        movementCube.update = {
            movementCube.inSubMatrix {
                basicTranslateZ -= self.panGestYDelta
                basicTranslateX -= self.panGestXDelta
                movementCube.tranlate(z: basicTranslateZ)
                movementCube.tranlate(x: basicTranslateX)
                movementCube.inSubMatrix {
                    orbitalRotationY -= 0.01
                    movementCube.rotate(y: orbitalRotationY)
                    movementCube.inSubMatrix {
                        movementCube.tranlate(z: 2.0)
                    }
                }
            }
        }
        renderManager.addNode(movementCube)
        setupGesture()
    }
    
    private func setupGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(MetalManager.pan))
        view.addGestureRecognizer(pan)
    }
    
    @objc private func pan(panGesture: UIPanGestureRecognizer) {
        let pointInView = panGesture.location(in: view)
        if panGesture.state == UIGestureRecognizer.State.changed {
            let xDelta = Float((lastPanLocation.x - pointInView.x) / view.bounds.width) * panSensitivity
            let yDelta = Float((lastPanLocation.y - pointInView.y) / view.bounds.width) * panSensitivity
            panGestXDelta = xDelta
            panGestYDelta = yDelta
        } else {
            panGestXDelta = 0
            panGestYDelta = 0
        }
        lastPanLocation = pointInView
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
