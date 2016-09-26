//
//  CaptureSettingsViewController.swift
//  AVCaptureSample
//
//  Created by Simon Kim on 25/09/2016.
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import UIKit

enum CaptureSettingsKey {
    case cameraPosition     // AVCaptureDevicePosition
    case videoDimensions    // CMVideoDimensions
    case frameRate          // Float
    case bitRate            // Float
    case stereoView         // Bool
    case recording          // Bool
}

protocol CaptureSettingsDelegate {
    func captureSettings(done: CaptureSettingsViewController)
    func captureSettings(_ controller:CaptureSettingsViewController, didChange key: CaptureSettingsKey, value: Any? )
}

class CaptureSettingsViewController: UITableViewController {
    
    var delegate: CaptureSettingsDelegate?
    
    @IBAction func actionDone(_ sender: AnyObject) {
        delegate?.captureSettings(done: self)
    }
    
    @IBAction func actionCameraPositionChange(_ sender: AnyObject) {
    }
    
    @IBAction func actionVideoDimensions(_ sender: AnyObject) {
    }
    
    @IBAction func actionBitrateChange(_ sender: AnyObject) {
    }
    
    @IBAction func actionStereoView(_ sender: AnyObject) {
    }
    
    @IBAction func actionRecordingChange(_ sender: UISwitch) {
        delegate?.captureSettings(self, didChange: .recording, value: sender.isOn)
    }
}
