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

enum CaptureSettingsDismissOption {
    case none
    case viewRecordings
}

protocol CaptureSettingsDelegate {
    func captureSettings(_ settingsViewController: CaptureSettingsViewController,
                         didDismissWithOption option: CaptureSettingsDismissOption)
    func captureSettings(_ controller:CaptureSettingsViewController, didChange key: CaptureSettingsKey, value: Any? )
}

class CaptureSettingsViewController: UITableViewController {
    
    @IBOutlet weak var switchRecording: UISwitch!
    @IBOutlet weak var switchStereoView: UISwitch!
    var delegate: CaptureSettingsDelegate?
    
    fileprivate var _settings: [CaptureSettingsKey: Any] = [:]
    
    override func viewDidLoad() {
    
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapSurface(_:)))
        self.view.addGestureRecognizer(gesture)
        
        updateUI(withSettings: _settings)
    }
    
    @IBAction func actionDone(_ sender: AnyObject) {
        delegate?.captureSettings(self, didDismissWithOption: .none)
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
    
    @IBAction func actionViewRecordings(_ sender: AnyObject) {
        delegate?.captureSettings(self, didDismissWithOption: .viewRecordings)
    }
    
    // MARK: Gesture
    func didTapSurface(_ sender: UITapGestureRecognizer) {
        delegate?.captureSettings(self, didDismissWithOption: .none)
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
            
            switch(setting.key) {
            case .recording:
                switchRecording.isOn = setting.value as! Bool
                break
            case .stereoView:
                switchStereoView.isOn = setting.value as! Bool
                break
                
            default:
                break
            }
            
        }
    }
}
