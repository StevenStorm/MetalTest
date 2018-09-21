//
//  ViewController.swift
//  MetalTest
//
//  Created by Local István Gulyás on 9/18/18.
//  Copyright © 2018 Local István Gulyás. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    var metalManager: MetalManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        guard let view = view as? MTKView, let device = MTLCreateSystemDefaultDevice() else {
            return
        }
        metalManager = MetalManager(device: device)
        metalManager?.view = view
        metalManager?.createRenderPipeLine()
        metalManager?.createCommandQueue()
        metalManager?.createNode()
        
    }
    
}


