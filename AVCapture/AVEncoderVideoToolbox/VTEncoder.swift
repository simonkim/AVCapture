//
//  VTEncoder.swift
//  AVCapture
//
//  Created by Simon Kim on 2016. 9. 10..
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import VideoToolbox

public struct H264ParameterSets {
    var sps: NSData?
    var pps: NSData?
    public var NALHeaderLength: Int32 = 0
    public var avcC: NSData?
    
    /* true of NALHeaderLength > 0 and at least one of sps or pps contains data */
    var valid: Bool {
        return NALHeaderLength > 0 && (sps != nil || pps != nil)
    }
    
    mutating func addParameterSet(p: UnsafePointer<UInt8>, length: Int) {
        if let type = NALUnitType(rawValue: Int8(UInt8(p[0] & UInt8(0x1f)))) {
            switch(type) {
                
            case .SPS:
                sps = NSData(bytes: p, length: length)
                break
                
            case .PPS:
                pps = NSData(bytes: p, length: length)
                break
                
            default:
                // discard
                break
            }
        }
    }
    
    public init(withFormatDescription formatDescription:CMFormatDescription) {
        
        // get parameter set count and nal header length
        let info = formatDescription.getH264ParameterSetInfo()
        if info.status == noErr {
            
            self.NALHeaderLength = info.NALHeaderLength
            
            // walk each parameter set
            for i in 0...info.count {
                let result = formatDescription.getH264ParameterSet(at: i)
                if result.status == noErr && result.length > 0 && result.p != nil {
                    addParameterSet(p: result.p!, length: result.length)
                }
            }
        }
        
        let propertyList = CMFormatDescriptionGetExtension(formatDescription, "SampleDescriptionExtensionAtoms" as CFString)
        if propertyList != nil {
            let atoms = propertyList as! NSDictionary
            if let avcC = atoms.object(forKey: "avcC"), avcC is NSData {
                self.avcC = avcC as? NSData
            }
        }
        
    }
}
/**
 * 1. Init with size
 * 2. assign onEncoded and onParameterSets closures
 * 3. repeat calling encode
 * 4. Call close() to finish
 */

class VTEncoder {
    var session: VTCompressionSession? = nil
    var parameterSets: H264ParameterSets? = nil
    
    var onEncoded: VideoToolbox.VTCompressionOutputHandler? = nil
    var onParameterSets: ((H264ParameterSets)->Void)? = nil
    
    static let defaultBitrate: Int = 1024 * 1024
    
    private var timingInfo: CMSampleTimingInfo = CMSampleTimingInfo()
    
    init(width:Int32, height:Int32, bitrate:Int = defaultBitrate) {
        session = VTCompressionSession.create(width: width, height: height)
        if let session = session {
            print("Encoder \(width) x \(height) @ \(bitrate)")
            VTSessionSetProperty(session, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CAVLC)
            VTSessionSetProperty(session, kVTCompressionPropertyKey_RealTime, true as CFTypeRef)
            VTSessionSetProperty(session, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel)
            VTSessionSetProperty(session, kVTCompressionPropertyKey_AverageBitRate, NSNumber(value: bitrate))
        } else {
            print("VTEncoder: Failed to create encoder")
        }
    }
    
    func encode(sampleBuffer: CMSampleBuffer!) {
        guard let session = session else {
            // session not valid
            return
        }
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let status = CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timingInfo)
        if status == noErr {
            var infoFlags = VTEncodeInfoFlags(rawValue: 0) // kVTEncodeInfo_Asynchronous | kVTEncodeInfo_FrameDropped
            let frameProperties : CFDictionary? = nil
            VTCompressionSessionEncodeFrameWithOutputHandler(
                session,
                imageBuffer!,
                timingInfo.presentationTimeStamp,
                timingInfo.duration,
                frameProperties,
                &infoFlags,
                encoded)
            
        }
    }
    
    private func encoded(status: OSStatus, infoFlags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) {
        if let sampleBuffer = sampleBuffer,
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
            
            if parameterSets == nil {
                let ps = H264ParameterSets(withFormatDescription: formatDescription)
                if ps.valid {
                    onParameterSets?(ps)
                }
                parameterSets = ps
            }
            
            self.onEncoded?(status, infoFlags, sampleBuffer)
        }
    }
    
    func close() {
        guard let session = session else {
            // session not valid
            return
        }
        
        VTCompressionSessionCompleteFrames(session, CMTime())
        VTCompressionSessionInvalidate(session)
    }
}
