//
//  ViewController.swift
//  MetalTest
//
//  Created by Local István Gulyás on 9/18/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import UIKit
import MetalKit
import simd

class ViewController: UIViewController {
    
    private var metalManager: MetalManager?
    
//    private var light = Light(color: (1.0,1.0,1.0), ambientIntensity: 0.5, direction: (1.0, 1.0, -1.0), diffuseIntensity: 0.8, shininess: 10, specularIntensity: 2)
    private var light = Light(color: float3(1.0,1.0,1.0), ambientIntensity: 0.2, position: float4(0.0,0.0,0.0,1.0), direction: float3(1.0,1.0,1.0), diffuseIntensity: 1.0, shininess: 10, specularIntensity: 1)
    
    private let panSensitivity: Float = 5.0
    private var lastPanLocation: CGPoint!
    private var panGestX: Float = 0.0
    private var panGestY: Float = 0.0
    private var panGestXDelta: Float = 0.0
    private var panGestYDelta: Float = 0.0
    private let acceleration: Float = 0.03
    
    @IBOutlet var mtkView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        metalManager = MetalManager.buildMetalManager(view: mtkView)
        metalManager?.delegate = self
        createNode()
    }
    
    func createNode() {
        guard let metalManager = metalManager else { return }
        let rotationCube = Node.buildCube(manager: metalManager, light: light)
        var basicTranslateZ: Float = 0.0
        var basicTranslateX: Float = 0.0
        var rotation: Float = 0.0
        rotationCube.update = {
            basicTranslateZ -= self.panGestYDelta
            basicTranslateX -= self.panGestXDelta
            rotationCube.tranlate(z: basicTranslateZ)
            rotationCube.tranlate(x: basicTranslateX)
            rotationCube.scale(scale: 0.5)
            rotationCube.inSubMatrix {
                rotation += 0.01
                rotationCube.rotate(x: rotation)
            }
        }
        let movementCube = Node.buildCube(manager: metalManager, light: light)
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
        setupGesture()
    }
    
    private func setupGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(ViewController.pan))
        view.addGestureRecognizer(pan)
    }
    
    @objc private func pan(panGesture: UIPanGestureRecognizer) {
        let pointInView = panGesture.location(in: view)
        if panGesture.state == UIGestureRecognizer.State.changed {
            let xDelta = Float((lastPanLocation.x - pointInView.x) / view.bounds.width) * panSensitivity
            let yDelta = Float((lastPanLocation.y - pointInView.y) / view.bounds.width) * panSensitivity
            panGestXDelta = xDelta
            panGestYDelta = yDelta
        }
        lastPanLocation = pointInView
    }
    
}

extension ViewController: MetalManagerDelegate {
    
    func didRenderScene() {
        if panGestXDelta < -acceleration {
            panGestXDelta += acceleration
        } else if panGestXDelta > acceleration {
            panGestXDelta -= acceleration
        } else {
            panGestXDelta = 0.0
        }
        if panGestYDelta < -acceleration {
            panGestYDelta += acceleration
        } else if panGestYDelta > acceleration {
            panGestYDelta -= acceleration
        } else {
            panGestYDelta = 0.0
        }
    }
    
}


