//
//  ViewController.swift
//  AVCaptureSample
//
//  Created by Simon Kim on 24/09/2016.
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import UIKit
import AVCapture
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var settingsContainer: UIView!
    @IBOutlet weak var activityRecording: UIActivityIndicatorView!
    
    var captureService: AVCaptureService!
    var previewLayerSet: Bool = false
    
    var recordingController: AssetRecordingController = AssetRecordingController(compressAudio: true,
                                                                                 compressVideo: true)
    
    fileprivate var stereoViewControl: StereoViewControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // double-tap shortcut to start recording
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(didTapPreviewSurface(_:)))
        doubleTap.numberOfTapsRequired = 2
        preview.addGestureRecognizer(doubleTap)

        // tap to show the settings
        settingsContainer.isHidden = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapPreviewSurface(_:)))
        gesture.require(toFail: doubleTap)
        preview.addGestureRecognizer(gesture)
        
        let serviceClient = AVCaptureClientSimple()
        serviceClient.dataDelegate = self
        serviceClient.options = [
            .encodeVideo(false),
            .videoDimensions(CMVideoDimensions(width: 1920, height: 1080)),
            .videoFrameRate(60)
        ]
        captureService = AVCaptureService(client: serviceClient)
        if captureService.start() {
            stereoViewControl = StereoViewControl(previewLayer: captureService.previewLayer!,
                                                  superlayer: preview.layer,
                                                  masterClock: captureService.masterClock)
        }
    }

    override func viewDidLayoutSubviews() {
        if let previewLayer = captureService.previewLayer {
            if !previewLayerSet {
                preview.layer.addSublayer(previewLayer)
                previewLayerSet = true
                self.updatePreviewLayout()
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {

        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { (coordinator) in
            self.updatePreviewLayout()
        }) { (coordinator) in
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updatePreviewLayout() {
        guard let previewLayer = self.captureService.previewLayer else {
            return
        }
        let orientation = AVCaptureVideoOrientation.from(interfaceOrientation: UIApplication.shared.statusBarOrientation)
        previewLayer.connection.videoOrientation = orientation
        
        if self.stereoViewControl != nil && self.stereoViewControl!.enabled {
            self.stereoViewControl?.updatePreviewLayout(orientation: orientation)
        } else {
            previewLayer.frame = self.preview.layer.bounds
        }
    }
}

extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "captureSettings" {
            let dest = segue.destination as! CaptureSettingsViewController
            dest.delegate = self
            dest.set(key:.recording, value: recordingController.recording)
        }
    }
}

// MARK: Capture Settings
extension ViewController: CaptureSettingsDelegate {

    func didTapPreviewSurface(_ sender: UITapGestureRecognizer) {
        
        if sender.numberOfTapsRequired == 2 {
            toggleRecording(on: !recordingController.recording)
        } else {
            for vc in self.childViewControllers {
                if vc is CaptureSettingsViewController {
                    let settingsViewController = vc as! CaptureSettingsViewController
                    settingsViewController.set(key:.recording, value: recordingController.recording)
                }
            }
            
            UIView.animate(withDuration: 0.5) {
                self.settingsContainer.isHidden = false
            }
        }
    }

    func captureSettings(done: CaptureSettingsViewController) {
        UIView.animate(withDuration: 0.5) { 
            self.settingsContainer.isHidden = true
        }
    }
    
    func captureSettings(_ controller:CaptureSettingsViewController, didChange key: CaptureSettingsKey, value: Any? )
    {
        switch(key) {
        case .recording:
            if let on = value as? Bool {
                toggleRecording(on: on)
            }
            break
            
        case .stereoView:
            if let on = value as? Bool {
                guard let stereoViewControl = stereoViewControl else {
                    break
                }
                stereoViewControl.enabled = on
                updatePreviewLayout()
            }
            break
        default:
            break
        }
    }
    
    func toggleRecording(on: Bool) {
        
        recordingController.toggleRecording(on: on)
        activityRecording.isHidden = !on
        if on {
            activityRecording.startAnimating()
        } else {
            activityRecording.stopAnimating()
        }
    }
}

extension ViewController: AVCaptureClientDataDelegate {
    
    func client(client: AVCaptureClient, didConfigureVideoSize videoSize: CGSize )
    {
        recordingController.videoSize = CMVideoDimensions(width: Int32(videoSize.width),
                                                          height: Int32(videoSize.height))
    }
    
    func client(client: AVCaptureClient, output sampleBuffer: CMSampleBuffer )
    {
        if client.mediaType == kCMMediaType_Video {
            stereoViewControl?.enqueue(sampleBuffer)
        }
        recordingController.append(sbuf: sampleBuffer)
    }
}

