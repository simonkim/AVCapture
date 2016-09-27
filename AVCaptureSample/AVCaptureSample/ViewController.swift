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

    var captureService: AVCaptureService!
    var previewLayerSet: Bool = false
    
    var recordingController: AssetRecordingController = AssetRecordingController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let serviceClient = AVCaptureClientSimple()
        serviceClient.dataDelegate = self
        captureService = AVCaptureService(client: serviceClient)
        if captureService.start() {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapPreview(_:)))
            view.addGestureRecognizer(gesture)
        }
        
    }

    override func viewDidLayoutSubviews() {
        if let previewLayer = captureService.previewLayer {
            if !previewLayerSet {
                view.layer.addSublayer(previewLayer)
                previewLayerSet = true
                previewLayer.frame = self.view.layer.bounds
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
            previewLayer.frame = self.view.layer.bounds
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

extension ViewController {

    func didTapPreview(_ sender: UIView)
    {
        recordingController.toggleRecording(on: !recordingController.recording)
    }
}
