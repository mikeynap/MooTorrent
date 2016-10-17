//
//  ViewController.swift
//  MooTorrent
//
//  Created by mnapolit on 10/11/16.
//  Copyright © 2016 Micmoo. All rights reserved.
//

import Cocoa
class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        EZTV.init()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

