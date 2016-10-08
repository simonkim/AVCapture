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
    
    @IBOutlet weak var switchRecording: UISwitch!
    var delegate: CaptureSettingsDelegate?
    
    fileprivate var _settings: [CaptureSettingsKey: Any] = [:]
    
    override func viewDidLoad() {
    
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapSurface(_:)))
        self.view.addGestureRecognizer(gesture)
        
        updateUI(withSettings: _settings)
    }
    
    @IBAction func actionDone(_ sender: AnyObject) {
        delegate?.captureSettings(done: self)
    }
    
    @IBAction func actionCameraPositionChange(_ sender: AnyObject) {
    }
    
    @IBAction func actionVideoDimensions(_ sender: AnyObject) {
    }
    
    @IBAction func actionBitrateChange(_ sender: AnyObject) {
    }
    
    @IBAction func actionStereoView(_ sender: UISwitch) {
        delegate?.captureSettings(self, didChange: .stereoView, value: sender.isOn)
    }
    
    @IBAction func actionRecordingChange(_ sender: UISwitch) {
        delegate?.captureSettings(self, didChange: .recording, value: sender.isOn)
    }
    
    // MARK: Gesture
    func didTapSurface(_ sender: UITapGestureRecognizer) {
        delegate?.captureSettings(done: self)
    }
}

// MARK: - Settings
extension CaptureSettingsViewController {
    func set(key: CaptureSettingsKey, value: Any)
    {
        _settings[key] = value
        
        if !isViewLoaded {
            return
        }
        
        updateUI(withSettings: _settings)
    }

    func updateUI(withSettings settings: [CaptureSettingsKey: Any])
    {
        for setting in settings {
            if setting.key == .recording {
                switchRecording.isOn = setting.value as! Bool
            }
        }
    }
}
