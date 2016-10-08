//
//  RecordingsCollection.swift
//  AVCaptureSample
//
//  Created by Simon Kim on 08/10/2016.
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class RecordingsCollection {
    func recordings() -> [AVAsset] {
        
        var result: [AVURLAsset] = []
        
        let fileManager = FileManager.default
        let URL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: URL,
                                                               includingPropertiesForKeys: nil)
            let recordings = contents.filter { (URL) -> Bool in
                return URL.pathExtension == "mov"
            }
            
            result = recordings.map { (URL) -> AVURLAsset in
                return AVURLAsset(url: URL)
            }
        } catch (let error) {
            print("Error loading recordings: \(error)")
        }
        
        return result
    }
    
    func queryThumbnail(forAsset asset: AVAsset,
                        maxSize: CGSize,
                        block: @escaping (UIImage?)->Void) {
        
        let time = CMTime(seconds: 0, preferredTimescale: 1000)
        
        let gen = AVAssetImageGenerator(asset: asset)
        gen.maximumSize = maxSize
        gen.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { (reqTime, cgImage, actualTime, result, error) in
            if cgImage != nil {
                block(UIImage(cgImage: cgImage!))
            } else {
                block(nil)
            }
        }
        
    }
    
    static func recordingFilePath(with name:String) -> String? {
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

}
