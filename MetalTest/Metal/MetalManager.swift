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
    private var objectToDraw: Node?
    private var pipelineState: MTLRenderPipelineState!
    private var defaultLibrary: MTLLibrary?
    private var fragmentProgram: MTLFunction?
    private var vertexProgram: MTLFunction?
    private let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    private var commandQueue: MTLCommandQueue?
    private var projectionMatrix = float4x4()
    private var worldModelMatrix = float4x4()
    
    private let panSensitivity: Float = 5.0
    private var lastPanLocation: CGPoint!
    
    weak var view: MTKView? {
        didSet {
            view?.delegate = self
            view?.preferredFramesPerSecond = 60
            view?.clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0)
            view?.device = device
            setupProjectionMatrix()
        }
    }
    
    private var textureLoader: MTKTextureLoader
    
    init(device: MTLDevice) {
        self.device = device
        self.textureLoader = MTKTextureLoader(device: device)
        defaultLibrary = device.makeDefaultLibrary()
        worldModelMatrix.translate(0.0, y: 0.0, z: -7.0)
        worldModelMatrix.rotateAroundX(float4x4.degrees(toRad: 45), y: 0.0, z: 0.0)
    }
    
    private func setupProjectionMatrix() {
        guard let view = self.view else { return }
        projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85), aspectRatio: Float(view.bounds.width/view.bounds.height), nearZ: 0.01, farZ: 100.0)
    }
    
    func createNode() {
        guard let commandQueue = commandQueue else {
            return
        }
        objectToDraw = Cube(device: device, commandQ: commandQueue, textureLoader: textureLoader)
        setupGesture()
    }
    
    private func loadFragmentProgram(programName: String) {
        fragmentProgram = defaultLibrary?.makeFunction(name: programName)
    }
    
    private func loadVertexProgram(programName: String) {
        vertexProgram = defaultLibrary?.makeFunction(name: programName)
    }
    
    func createRenderPipeLine() {
        loadFragmentProgram(programName: "basic_fragment")
        loadVertexProgram(programName: "basic_vertex")
        
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            print("Can't make renderPipelineState object")
        }
    }
    
    func createCommandQueue() {
        commandQueue = device.makeCommandQueue()
    }
    
    func render(drawable: CAMetalDrawable?) {
        guard let drawable = drawable, let commandQueue = self.commandQueue else {
            return
        }
        objectToDraw?.render(commandQueue: commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0))
        
    }
    
    private func setupGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(MetalManager.pan))
        view?.addGestureRecognizer(pan)
    }
    
    @objc private func pan(panGesture: UIPanGestureRecognizer) {
        guard let view = self.view else {
            return
        }
        let pointInView = panGesture.location(in: view)
        if panGesture.state == UIGestureRecognizer.State.changed {
            let xDelta = Float((lastPanLocation.x - pointInView.x) / view.bounds.width) * panSensitivity
            let yDelta = Float((lastPanLocation.y - pointInView.y) / view.bounds.width) * panSensitivity
            objectToDraw?.rotationY -= xDelta
            objectToDraw?.rotationX -= yDelta
            
        }
        lastPanLocation = pointInView
    }
    
}

extension MetalManager: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85), aspectRatio: Float(view.bounds.width/view.bounds.height), nearZ: 0.01, farZ: 100.0)
    }
    
    func draw(in view: MTKView) {
        render(drawable: view.currentDrawable)
    }
    
}
