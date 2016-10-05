//
//  CMVideoFormatDescription.swift
//  AVCapture
//
//  Created by Simon Kim on 2016. 9. 10..
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import CoreMedia

extension CMVideoFormatDescription {
    /*
     * returns number of parameter sets and size of NALUnitLength in bytes
     */
    func getH264ParameterSetInfo() -> (status: OSStatus, count: Int, NALHeaderLength: Int32) {
        var count: Int = 0
        var NALHeaderLength: Int32 = 0
        
        // get parameter set count and nal header length
        let status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            self, 0, nil, nil, &count, &NALHeaderLength)
        
        return (status: status, count: count, NALHeaderLength: NALHeaderLength)
    }
    
    func getH264ParameterSet(at index:Int) -> (status: OSStatus, p: UnsafePointer<UInt8>?, length: Int){
        var pParamSet: UnsafePointer<UInt8>? = nil
        var length: Int = 0
        
        let status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            self, index, &pParamSet, &length, nil, nil)
        
        return (status: status, p: pParamSet, length: length)
    }
}

public extension CMSampleBuffer {
    public var formatDescription: CMFormatDescription?
    {
        return CMSampleBufferGetFormatDescription(self)
    }
    
    public var sampleTimingInfo: CMSampleTimingInfo? {
        get {
            var timingInfo: CMSampleTimingInfo? = CMSampleTimingInfo()
            let status = CMSampleBufferGetSampleTimingInfo(self, 0, &timingInfo!)
            if ( status != noErr ) {
                timingInfo = nil
            }
            return timingInfo
        }
    }
    
    public var presentationTimeStamp: CMTime {
        return CMSampleBufferGetPresentationTimeStamp(self)
    }
    
    public var decodeTimeStamp: CMTime {
        return CMSampleBufferGetDecodeTimeStamp(self)
    }
    
    public func makeDataReady() -> OSStatus {
        return CMSampleBufferMakeDataReady(self)
    }
}

extension CMFormatDescription {
    public var mediaSubType: FourCharCode
    {
        return CMFormatDescriptionGetMediaSubType(self)
    }
}

extension CMVideoDimensions: Equatable {
    public static func == (lhs: CMVideoDimensions, rhs: CMVideoDimensions) -> Bool {
        return
            lhs.width == rhs.width &&
                lhs.height == rhs.height
    }
}
