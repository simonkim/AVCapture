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

struct CaptureStatus {
    var stereoViewEnabled: Bool = false
}

class ViewController: UIViewController {

    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var settingsContainer: UIView!
    @IBOutlet weak var activityRecording: UIActivityIndicatorView!
    
    var captureService: AVCaptureService!
    
    var recordingController: AssetRecordingController = AssetRecordingController(compressAudio: true,
                                                                                 compressVideo: true)
    fileprivate var _captureStarted = false
    /// Capture status just before stop. Status used to restore on restart.
    fileprivate var _captureStopStatus: CaptureStatus = CaptureStatus()
    
    fileprivate var stereoViewControl: StereoViewControl?
    

    fileprivate var captureSettingsViewController: CaptureSettingsViewController? {
        for vc in self.childViewControllers {
            if vc is CaptureSettingsViewController {
                return (vc as! CaptureSettingsViewController)
            }
        }
        return nil
    }
    
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
        
        startCapture(captureService: captureService, layout: false)
    }

    override func viewDidLayoutSubviews() {
        if let previewLayer = captureService.previewLayer {
            if previewLayer.superlayer != preview.layer {
                preview.layer.addSublayer(previewLayer)
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
        if _captureStarted == false {
            return
        }

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
    
    
    func didTapPreviewSurface(_ sender: UITapGestureRecognizer) {
        
        if sender.numberOfTapsRequired == 2 {
            toggleRecording(on: !recordingController.recording)
        } else {
            if let vc = captureSettingsViewController {
                vc.set(key:.recording, value: recordingController.recording)
            }
            
            UIView.animate(withDuration: 0.5) {
                self.settingsContainer.isHidden = false
            }
        }
    }
    
    // MARK: Capture Control
    func startCapture(captureService: AVCaptureService, layout: Bool = true) {
        if captureService.start() {
            stereoViewControl = StereoViewControl(previewLayer: captureService.previewLayer!,
                                                  superlayer: preview.layer,
                                                  masterClock: captureService.masterClock)
            _captureStarted = true
            
            // restore last capture status
            let stereoViewEnabled = _captureStopStatus.stereoViewEnabled
            stereoViewControl?.enabled = stereoViewEnabled
            if let vc = captureSettingsViewController {
                vc.set(key:.stereoView, value: stereoViewEnabled)
            }

            // optional layout
            if layout {
                if let previewLayer = self.captureService.previewLayer {
                    if previewLayer.superlayer != self.preview.layer {
                        self.preview.layer.addSublayer(previewLayer)
                    }
                    self.updatePreviewLayout()
                }
            }
        }
    }
    
    func stopCapture(captureService: AVCaptureService) {
        
        // Remember the last status
        _captureStopStatus.stereoViewEnabled = (stereoViewControl != nil && stereoViewControl!.enabled)
        
        if recordingController.recording {
            toggleRecording(on: !recordingController.recording)
        }
        stereoViewControl?.enabled = false
        captureService.stop()
        
        _captureStarted = false
    }
}

enum SegueID: String {
    case captureSettings = "captureSettings"
    case videoCollection = "videoCollection"
}

extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueID.captureSettings.rawValue {
            let dest = segue.destination as! CaptureSettingsViewController
            dest.delegate = self
            dest.set(key:.recording, value: recordingController.recording)
        } else if segue.identifier == SegueID.videoCollection.rawValue {
            let destNav = segue.destination as! UINavigationController
            let dest = destNav.topViewController as! RecordingsCollectionViewController
            dest.delegate = self
        }
    }
}

// MARK: Capture Settings
extension ViewController: CaptureSettingsDelegate {

    func captureSettings(_ settingsViewController: CaptureSettingsViewController, didDismissWithOption option: CaptureSettingsDismissOption) {

        self.settingsContainer.isHidden = true
        
        if option == .viewRecordings {
            self.performSegue(withIdentifier: SegueID.videoCollection.rawValue, sender: self)
            
            // 0.5 delay to hide screen distortion while stopping capture
            // Not animating
            UIView.animate(withDuration: 0.5, animations: {}, completion: { (finished) in
                self.stopCapture(captureService: self.captureService)
            })
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
        
        recordingController.recording = on
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

extension ViewController: RecordingsCollectionViewControllerDelegate {
    func recordingCollectionDidDismiss(_ viewController: RecordingsCollectionViewController)
    {
        self.startCapture(captureService: self.captureService)
        dismiss(animated: true) {
        }
    }
}
