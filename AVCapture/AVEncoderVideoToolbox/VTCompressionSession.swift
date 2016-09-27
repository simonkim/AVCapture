//
//  VTCompressionSession.swift
//  AVCapture
//
//  Created by Simon Kim on 2016. 9. 10..
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import VideoToolbox

extension VTCompressionSession {
    /**
     * Creates a video toolbox compression session
     
     * @param width Width of video in pixels
     * @return Newly created compression session
     *
     * Compression Property Keys
     kVTCompressionPropertyKey_AllowFrameReordering CFBoolean optional default=true
     kVTCompressionPropertyKey_AverageBitrate optional CFNumber<SInt32> default=0
     kVTCompressionPropertyKey_H264EntropyMode CFString optional default=unknown
     
     kVTH264EntropyMode_CAVLC
     kVTH264EntropyMode_CABAC
     kVTCompressionPropertyKey_RealTime optional CFBoolean default=unknown
     kVTCompressionPropertyKey_ProfileLevel CFString optional default=unknown
     
     kVTProfileLevelH264Main_AutoLevel
     */
    
    static func create(width: Int32, height: Int32, codecType: CMVideoCodecType = kCMVideoCodecType_H264) -> VTCompressionSession? {
        
        let encoderSpecification: CFDictionary? = nil
        let sourceImageBufferAttributes: CFDictionary? = nil
        let compressedDataAllocator: CFAllocator? = nil
        let outputCallbackRefCon: UnsafeMutableRawPointer? = nil
        
        var session: VTCompressionSession? = nil
        let status = VTCompressionSessionCreate(kCFAllocatorDefault,
                                                width, height,
                                                codecType,
                                                encoderSpecification,
                                                sourceImageBufferAttributes,
                                                compressedDataAllocator,
                                                nil,
                                                outputCallbackRefCon,
                                                &session)
        if ( status != noErr ) {
            print("VTCompressionSessionCreate() failed: \(status)")
        } // else, Sesstion created successfully

        return session
    }
}
