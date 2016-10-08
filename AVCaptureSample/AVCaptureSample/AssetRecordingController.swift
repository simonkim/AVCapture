//
//  AssetWritingController.swift
//  AVCaptureSample
//
//  Created by Simon Kim on 9/26/16.
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import AVCapture

import AVFoundation

struct AssetRecordingOptions {
    var compressAudio: Bool
    var compressVideo: Bool
    var videoDimensions: CMVideoDimensions
}

enum RecordingUserDefaultKey: String {
    case recordingSequence = "recordingSeq" // Int
    
    /// Get the next sequence number from user defaults and increase it by 1 for next call
    static var nextRecordingSequenceNumber: Int
    {
        let defaults = UserDefaults()
        let result = defaults.integer(forKey: recordingSequence.rawValue)
        defaults.set(result + 1, forKey: recordingSequence.rawValue)
        defaults.synchronize()
        
        return result
    }
}

class AssetRecordingController {
    
    var fileWriter: AVCFileWriter? = nil
    
    static var writerQueue: DispatchQueue = {
            return DispatchQueue(label: "writer")
    }()
    
    /// start or stop recording
    public var recording: Bool {
        get {
            return fileWriter != nil
        }
        
        set(newValue) {
            toggleRecording(on: newValue)
        }
    }
    
    /// Returns video dimensions currently set. Default is (0, 0)
    /// Set video dimenstions through this property before starting recording by 
    /// setting true to 'recording' property
    public var videoSize: CMVideoDimensions {
        get {
            return options.videoDimensions
        }
        set(newValue){
            options.videoDimensions = newValue
        }
    }
    
    private var options: AssetRecordingOptions
        
    public init(compressAudio: Bool = true, compressVideo: Bool = true)
    {
        self.options = AssetRecordingOptions(compressAudio: compressAudio,
                                             compressVideo: compressVideo,
                                             videoDimensions: CMVideoDimensions(width: 0, height: 0))
    }
    
    private func toggleRecording(on: Bool) {
        if on {
            let seq = RecordingUserDefaultKey.nextRecordingSequenceNumber
            if let path = RecordingsCollection.recordingFilePath(with: String(format:"recording-%03d.mov", seq)) {
                let audioSettings = AVCWriterSettings(compress: self.options.compressAudio)
                let videoSettings = AVCWriterVideoSettings(compress:self.options.compressVideo,
                                                           width:Int(options.videoDimensions.width),
                                                           height: Int(options.videoDimensions.height))
                
                let writer = AVCFileWriter(URL: Foundation.URL(fileURLWithPath: path), videoSettings: videoSettings, audioSettings: audioSettings) {
                    sender, status, info in
                    
                    print("Writer \(status.rawValue)")
                    switch(status) {
                    case .writerInitFailed, .writerStartFailed, .writerStatusFailed:
                        print("     : \(info)")
                        self.fileWriter = nil
                        sender.finish(silent: true)
                        break
                    case .finished:
                        print("Video recorded at \(path)")
                        break
                    default:
                        break
                    }
                }
                
                fileWriter = writer
            }
            
        } else {
            if let fileWriter = fileWriter {
                fileWriter.finish()
                self.fileWriter = nil
            }
        }
    }
    
    func append(sbuf: CMSampleBuffer) {
        type(of:self).writerQueue.async() {
            self.fileWriter?.append(sbuf: sbuf)
        }
    }
}
