//
//  ViewController.swift
//  Metal by Example
//
//  Created by Local István Gulyás on 11/21/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {

    var mtkView: MTKView!
    var renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mtkView = MTKView()
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mtkView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: mtkView.topAnchor),
            view.bottomAnchor.constraint(equalTo: mtkView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: mtkView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: mtkView.trailingAnchor)])
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Can't create MTLDevice")
        }
        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        renderer = Renderer(device: device, mtkView: mtkView)
        mtkView.delegate = renderer
    }
    
    

}

