//
//  AVCaptureVideoOrientation.swift
//  AVCapture
//
//  Created by Simon Kim on 24/09/2016.
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import AVFoundation

extension AVCaptureVideoOrientation {
    
    /// Converts UIInterfaceOrientation to AVCaptureVideoOrientation
    ///
    /// - parameter interfaceOrientation: UIInterfaceOrientation value that will be converted
    public static func from(interfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        var videoOrientation: AVCaptureVideoOrientation
        
        switch(interfaceOrientation) {
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
       
        return videoOrientation
    }
}
