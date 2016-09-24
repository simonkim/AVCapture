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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        captureService = AVCaptureService(client:AVCaptureClientSimple())
        captureService.start()
    }

    override func viewDidLayoutSubviews() {
        if let previewLayer = captureService.previewLayer {
            if !previewLayerSet {
                view.layer.addSublayer(previewLayer)
                previewLayerSet = true
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (coordinator) in
            if let previewLayer = self.captureService.previewLayer {
                previewLayer.frame = self.view.layer.bounds
            }
            
        }) { (coordinator) in
            let orientation = UIApplication.shared.statusBarOrientation
            guard let previewLayer = self.captureService.previewLayer else {
                return
            }
            
            var videoOrientation: AVCaptureVideoOrientation
            
            switch(orientation) {
            case .portrait:
                videoOrientation = .portrait
                break
            case .portraitUpsideDown:
                videoOrientation = .portraitUpsideDown
                break
            case .landscapeLeft:
                videoOrientation = .landscapeLeft
                break
            case .landscapeRight:
                videoOrientation = .landscapeRight
                break
            default:
                videoOrientation = .landscapeLeft
                break
            }
            
            previewLayer.connection.videoOrientation = videoOrientation
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

