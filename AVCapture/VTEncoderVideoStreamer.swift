//
//  VideoCaptureTest.swift
//  AVCapture
//
//  Created by Simon Kim on 2016. 9. 10..
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import CoreMedia
import AVFoundation

// FIXME: This class no need to be separate. Merge into VideoCapture class

class VTEncoderVideoStreamer {
    
    var videoSize: CGSize = CGSize()
    var parameterSets: H264ParameterSets?
    
    var preferredBitrate: Int = 1024 * 1024
    
    var onOutput: ((_ sampleBuffer: CMSampleBuffer)->Void)? = nil
    
    lazy var encoder: VTEncoder = {
        let encoder = VTEncoder(width: Int32(self.videoSize.width), height: Int32(self.videoSize.height), bitrate: self.preferredBitrate)
        encoder.onEncoded = { status, infoFlags, sampleBuffer in
            if let sampleBuffer = sampleBuffer, status == noErr {
                self.onOutput?(sampleBuffer)
            }
        }
        
        encoder.onParameterSets = { parameterSets in
            self.parameterSets = parameterSets
        }
        return encoder
    }()
    
    init(preferredBitrate: Int) {
        self.preferredBitrate = preferredBitrate
    }
    
    func add(sampleBuffer: CMSampleBuffer!) {
        encoder.encode(sampleBuffer: sampleBuffer)
    }
    
    func stop() {
        encoder.close()
    }

}


