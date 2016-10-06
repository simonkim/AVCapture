//
//  StereoViewControl.swift
//  Encoder Demo
//
//  Created by Simon Kim on 10/5/16.
//  Copyright © 2016 Geraint Davies. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class StereoViewControl {
    var enabled: Bool = false {
        willSet(newValue) {
            setStereoView(enabled: newValue)
        }
    }
    
    var capturePreviewLayer: AVCaptureVideoPreviewLayer? = nil
    var superlayer: CALayer
    var masterClock: CMClock
    
    fileprivate var rightPOVLayer: AVSampleBufferDisplayLayer? = nil
    
    fileprivate static var renderQueue: DispatchQueue = {
        return DispatchQueue(label: "render")
    }()
    
    init(previewLayer: AVCaptureVideoPreviewLayer,
         superlayer: CALayer,
         masterClock: CMClock)
    {
        
        capturePreviewLayer = previewLayer
        self.superlayer = superlayer
        self.superlayer.addSublayer(previewLayer)
        
        self.masterClock = masterClock
    }
    
    func createSampleBufferDisplayLayer() -> AVSampleBufferDisplayLayer {
        
        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = AVLayerVideoGravityResizeAspect
        return layer
    }

    /// horizontal distance scale factor from center for each side
    var horzDistanceScale: CGFloat = 0.05

    func updatePreviewLayout(orientation: AVCaptureVideoOrientation? = nil) {
        let superbounds = superlayer.bounds
        
        let width = (superbounds.width / 2)
        let hgap = width * horzDistanceScale
        let left = CGRect(origin: superbounds.origin, size: CGSize(width: width - hgap, height: superbounds.height))
        let origin = CGPoint(x: left.origin.x + width + hgap * 2, y:left.origin.y)
        let right = CGRect(origin: origin, size: left.size)
        
        capturePreviewLayer?.frame = left
        rightPOVLayer?.frame = right

        if let orientation = orientation {
            var transform: CATransform3D
            if orientation == .landscapeRight {
                transform = CATransform3DIdentity
            } else {
                transform = CATransform3DRotate(CATransform3DIdentity, CGFloat(M_PI), 0.0, 0.0, -1.0)
            }
            rightPOVLayer?.transform = transform
        }

    }
    
    func setStereoView(enabled: Bool) {

        if self.enabled == enabled {
            return
        }
        
        if enabled {
            if rightPOVLayer == nil {
                let rightLayer = createSampleBufferDisplayLayer()
                var timebase: CMTimebase?
                CMTimebaseCreateWithMasterClock(kCFAllocatorDefault, masterClock, &timebase)
                if let timebase = timebase {
                    CMTimebaseSetRate(timebase, 1.0)
                    CMTimebaseSetTime(timebase, CMClockGetTime(masterClock))
                    rightLayer.controlTimebase = timebase
                }
                rightPOVLayer = rightLayer
            }
            superlayer.addSublayer(rightPOVLayer!)
        } else {
            rightPOVLayer?.removeFromSuperlayer()
        }
    }

    func enqueue(_ sbuf: CMSampleBuffer) {
        type(of:self).renderQueue.async {
            self.rightPOVLayer?.enqueue(sbuf)
        }
    }
}
