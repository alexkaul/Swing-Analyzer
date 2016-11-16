//
//  ViewController.swift
//  Swing Analyzer
//
//  Created by Alexandra Kaulfuss on 16.11.16.
//  Copyright © 2016 Alexandra Kaulfuss. All rights reserved.
//

struct Swing {
    var loggingTime: [Date]
    var accelerationX: [Double]
    var accelerationY: [Double]
    var accelerationZ: [Double]
    var motionPitch: [Double]
    var motionRoll: [Double]
    var motionYaw: [Double]
    var rotationX: [Double]
    var rotationY: [Double]
    var rotationZ: [Double]
}

import UIKit
import Charts
import CoreMotion
import CoreData
import SwiftyJSON
import AVFoundation

class ViewController: UIViewController, ChartViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
