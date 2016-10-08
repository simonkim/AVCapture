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
    var horzDistanceScale: CGFloat = 0.00
    var vertTopMarginScale: CGFloat = 0.15 // xiaomi vr play offset: 0.15
    var sizeScale: CGFloat = 0.88          // iPhone 7 plus size scale: 0.88

    func updatePreviewLayout(orientation: AVCaptureVideoOrientation? = nil) {
        let superbounds = superlayer.bounds
        
        let width = (superbounds.width / 2)
        let hgap = width * horzDistanceScale
        var origin = superbounds.origin
        origin.y += superbounds.size.height * vertTopMarginScale
        origin.x += (superbounds.size.width / 2.0)  * (1.0 - sizeScale) / 2
        let left = CGRect(origin: origin, size: CGSize(width: (width - hgap) * sizeScale, height: superbounds.height * sizeScale))
        origin = CGPoint(x: left.origin.x + width + hgap * 2, y:left.origin.y)
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
            rightPOVLayer?.flushAndRemoveImage()
        }
    }

    func enqueue(_ sbuf: CMSampleBuffer) {
        if enabled {
            self.rightPOVLayer?.enqueue(sbuf)
            // FIXME: flush() once came back from background to avoid 
            //        rightPOVLayer?.status == .failed
        }
    }
}
