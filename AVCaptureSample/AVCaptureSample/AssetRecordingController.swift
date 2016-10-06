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

class AssetRecordingController {
    
    var fileWriter: AVCFileWriter? = nil
    
    static var writerQueue: DispatchQueue = {
            return DispatchQueue(label: "writer")
    }()
    
    var recording: Bool {
        return fileWriter != nil
    }
    
    var videoSize: CMVideoDimensions {
        get {
            return options.videoDimensions
        }
        set(newValue){
            options.videoDimensions = newValue
        }
    }
    
    private var options: AssetRecordingOptions
    
    func recordingFilePath(with name:String) -> String? {
        let URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = URL.appendingPathComponent(name).path
        
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print( "Can't remove file: \(path)")
                return nil
            }
        }
        return path
    }
    
    public init(compressAudio: Bool = true, compressVideo: Bool = true)
    {
        self.options = AssetRecordingOptions(compressAudio: compressAudio,
                                             compressVideo: compressVideo,
                                             videoDimensions: CMVideoDimensions(width: 0, height: 0))
    }
    
    public func toggleRecording(on: Bool) {
        if on {
            if let path = recordingFilePath(with: "recording.mov") {
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
