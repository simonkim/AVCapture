//
//  AVCFileWriter.swift
//  AVCapture
//
//  Created by Simon Kim on 9/26/16.
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import AVFoundation

public struct AVCWriterSettings {
    /* Need compression if true */
    var compress: Bool
    /* Overrides compress property */
    var outputSettings:[String: Any]? = nil
        
    func buildOutputSettings() -> [String: Any]? {
        let result: [String: Any]?
        if outputSettings != nil {
            result = outputSettings
        } else if compress {
            result = type(of:self).outputSettingsAACCompression
        } else {
            result = nil
        }
        return result
    }
    
    static var outputSettingsAACCompression: [String: Any]? = {
        return [
            AVFormatIDKey: NSNumber(value:kAudioFormatMPEG4AAC) as AnyObject,
            AVEncoderBitRateKey: 64000 as AnyObject,
            AVSampleRateKey: 44100.0 as AnyObject,
            AVNumberOfChannelsKey: 1 as AnyObject
        ]
    }()
    
    public init(compress: Bool, outputSettings: [String: Any]? = nil) {
        self.compress = compress
        self.outputSettings = outputSettings
    }
}

public struct AVCWriterVideoSettings {
    var basicSettings: AVCWriterSettings
    var width: Int
    var height: Int
    
    func buildOutputSettings() -> [String: Any]? {
        let result: [String: Any]?
        if basicSettings.outputSettings != nil {
            result = basicSettings.outputSettings
        } else if basicSettings.compress {
            result = type(of:self).outputSettingsH264Compression(width: width, height: height)
        } else {
            result = nil
        }
        return result
    }
    
    static func outputSettingsH264Compression(width:Int, height:Int) -> [String: Any] {
        return [
            AVVideoCodecKey: AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey: width as AnyObject,
            AVVideoHeightKey: height as AnyObject,
            AVVideoCompressionPropertiesKey: [AVVideoAllowFrameReorderingKey: true]
        ]
    }
    
    /// Initializer
    ///
    /// - parameter compress: true if compression is required
    /// - parameter width:    valid only if compression required, compress == true
    /// - parameter height:   valid only if compression required, compress == true
    ///
    /// - returns: instance
    public init(compress: Bool = false, width: Int = 0, height: Int = 0 ) {
        basicSettings = AVCWriterSettings(compress: compress)
        self.width = width
        self.height = height
    }
}

public class AVCFileWriter {
    
    public enum StatusKey: String {
        case initialized = "initialized"            // fileURL, width, height, compress
        case writerInitFailed = "initFailed"        // error
        case writerStartFailed = "startFailed"      // writerStatus, error
        case writerStatusFailed = "statusFailed"    // writerStatus, error
        case finished = "finished"                  //
    }
    
    public enum InfoKey: String {
        case writerStatus = "writerStatus"  //  AVAssetWriterStatus
        case error = "error"                // ErrorType
        case fileURL = "fileURL"            // NSURL
        case width = "width"                // Int
        case height = "height"              // Int
        case compress = "compress"          // Bool
    }
    
    private var writer: AVAssetWriter?
    private var writerInputVideo: AVAssetWriterInput?
    private var writerInputAudio: AVAssetWriterInput?
    private let on: (_ sender: AVCFileWriter, _ status: StatusKey, _ info: [InfoKey: Any]) -> Void
    
    /* status after initialization. initialization failed if status != .initialized */
    public let status: StatusKey
    public let statusInfo:[InfoKey: Any]
    
    fileprivate var firstAudioSampleHandled: Bool = false
    
    static func writerInputVideo(settings: AVCWriterVideoSettings?) -> AVAssetWriterInput? {
        guard let settings = settings else {
            return nil
        }

        let inputVideo = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: settings.buildOutputSettings())
        inputVideo.expectsMediaDataInRealTime = true
        return inputVideo
    }
    
    static func writerInputAudio(settings: AVCWriterSettings?) -> AVAssetWriterInput? {
        guard let settings = settings else {
            return nil
        }
        
        let inputAudio = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: settings.buildOutputSettings())
        inputAudio.expectsMediaDataInRealTime = true
        return inputAudio
    }
    
    /**
     * For already compressed samples, compress:, width:, and height: arguments can be omitted
     * ```
     * let videoSettings = AVCWriterVideoSettings(compress:false)
     * let audioSettings = AVCWriterSettings(compress: true)
     * let writer = AVCFileWriter(URL: URL, videoSettings: videoSettings, audioSettings: audioSettings )
     * ```
     */
    public init(URL:Foundation.URL,
                videoSettings: AVCWriterVideoSettings?,
                audioSettings: AVCWriterSettings?,
                onStatus:@escaping ((_ sender: AVCFileWriter, _ status: StatusKey, _ info:[InfoKey: Any]) -> Void) = { _, _, _ in }) {
        
        
        do {
            let writer = try AVAssetWriter(outputURL: URL, fileType: AVFileTypeQuickTimeMovie)
            
            if let inputVideo = type(of:self).writerInputVideo(settings: videoSettings) {
                writer.add(inputVideo)
                writerInputVideo = inputVideo
            }
            
            if let inputAudio = type(of:self).writerInputAudio(settings: audioSettings) {
                writer.add(inputAudio)
                writerInputAudio = inputAudio
            }
            
            self.writer = writer
            status = .initialized
            statusInfo = [.fileURL: URL]
        } catch(let error) {
            print("Error \(error)")
            
            status = .writerInitFailed
            statusInfo = [.error : error]
        }
        self.on = onStatus
    }
    

    
    public func append(sbuf sampleBuffer: CMSampleBuffer) {
        guard let writer = self.writer else {
            print("writer not initialized")
            return
        }
        
        guard let fd = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return
        }
        
        let mediaType = CMFormatDescriptionGetMediaType(fd)
        
        if CMSampleBufferDataIsReady(sampleBuffer) {
            if writer.status == .unknown {
                if writer.startWriting() {
                    let startTime = sampleBuffer.presentationTimeStamp
                    writer.startSession(atSourceTime: startTime)
                    //logger.d(String(format:"WRITER Start session at pts:%2.2f", startTime.seconds))
                } else {
                    on(self,.writerStartFailed, [.writerStatus: writer.status, .error: writer.error])
                    return
                }
            }
            if writer.status == .failed {
                on(self,.writerStatusFailed, [.writerStatus: writer.status, .error: writer.error])
                return
            }
            
            var input: AVAssetWriterInput? = nil
            if mediaType == kCMMediaType_Video {
                input = writerInputVideo
            } else if mediaType == kCMMediaType_Audio {
                input = writerInputAudio
            }
            
            if let input = input , input.isReadyForMoreMediaData {
                /*
                 * FIXME: Confirm if this is required for saving compressed audio samples
                if mediaType == kCMMediaType_Audio && !firstAudioSampleHandled  {
                    let duration = CMTime(seconds: 0.1, preferredTimescale: sampleBuffer.presentationTimeStamp.timescale)
                    let trimDuration = CMTimeCopyAsDictionary(duration, kCFAllocatorDefault)
                    CMSetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_TrimDurationAtStart, trimDuration, kCMAttachmentMode_ShouldNotPropagate)
                    firstAudioSampleHandled = true
                }
                */
                
                input.append(sampleBuffer)
            }
        }
    }
    
    public func finish(silent:Bool = false) {
        if let writer = self.writer {
            writer.finishWriting(completionHandler: {
                if !silent {
                    self.on(self,.finished, [:])
                }
            })
        }
    }
}

extension CMMediaType {
    var string: String {
        var result = "Other"
        switch(self) {
        case kCMMediaType_Video:
            result = "Video"
            break
            
        case kCMMediaType_Audio:
            result = "Audio"
            break
            
        default:
            break
        }
        return result
    }
}
