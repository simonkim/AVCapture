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
    
    var recordingController: AssetRecordingController = AssetRecordingController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // tap to show the settings
        settingsContainer.isHidden = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapPreviewSurface(_:)))
        preview.addGestureRecognizer(gesture)
        
        let serviceClient = AVCaptureClientSimple()
        serviceClient.dataDelegate = self
        captureService = AVCaptureService(client: serviceClient)
        if captureService.start() {
        }
    }

    override func viewDidLayoutSubviews() {
        if let previewLayer = captureService.previewLayer {
            if !previewLayerSet {
                preview.layer.addSublayer(previewLayer)
                previewLayerSet = true
                previewLayer.frame = preview.layer.bounds
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard let previewLayer = self.captureService.previewLayer else {
            return
        }

        coordinator.animate(alongsideTransition: { (coordinator) in
        }) { (coordinator) in
            let orientation = UIApplication.shared.statusBarOrientation
            previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.from(interfaceOrientation: orientation)
            previewLayer.frame = self.preview.layer.bounds
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "captureSettings" {
            let dest = segue.destination as! CaptureSettingsViewController
            dest.delegate = self
        }
    }
}

// MARK: Capture Settings
extension ViewController: CaptureSettingsDelegate {

    func didTapPreviewSurface(_ sender: UIGestureRecognizer) {
        UIView.animate(withDuration: 0.5) {
            self.settingsContainer.isHidden = false
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
                recordingController.toggleRecording(on: on)
                activityRecording.isHidden = !on
                if on {
                    activityRecording.startAnimating()
                } else {
                    activityRecording.stopAnimating()
                }
            }
            break
        default:
            break
        }
    }
    
}

extension ViewController: AVCaptureClientDataDelegate {
    
    func client(client: AVCaptureClient, didConfigureVideoSize videoSize: CGSize )
    {
        recordingController.videoSize = videoSize
    }
    
    func client(client: AVCaptureClient, output sampleBuffer: CMSampleBuffer )
    {
        recordingController.append(sbuf: sampleBuffer)
    }
}

