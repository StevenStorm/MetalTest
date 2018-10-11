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
        guard let view = view as? MTKView else {
            return
        }
        metalManager = MetalManager.buildMetalManager(view: view)
        metalManager?.createNode()
        
    }
    
}


