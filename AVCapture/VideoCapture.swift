//
//  VideoCapture.swift
//  AVCapture
//
//  Created by Simon Kim on 2016. 9. 11..
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import AVFoundation

class VideoCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureClient {
    var mediaType: CMMediaType {
        return kCMMediaType_Video
    }
    
    var preferredDevicePosition = AVCaptureDevicePosition.back
    var preferredSessionPreset = AVCaptureSessionPreset1280x720
    var preferredBitrate: Int = 1024 * 1024
    private var encode: Bool = false
    private var options: [AVCaptureClientOptionKey] = []
    
    private var encoder: VTEncoder? = nil
    
    var videoSize = CGSize(width: 1920, height: 1080)
    
    private static var captureQueue: DispatchQueue = {
        return DispatchQueue(label:"video-capture")
    }()
    
    private var input: AVCaptureDeviceInput? = nil
    private var output: AVCaptureVideoDataOutput? = nil
    
    override init() {
        super.init()
    }
    
    func configure(session:AVCaptureSession) {
        
        if let device = captureDevice(with: preferredDevicePosition) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                session.addInput(input)
                
                session.sessionPreset = self.preferredSessionPreset
                
                let output = AVCaptureVideoDataOutput()
                
                output.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as AnyHashable:
                        NSNumber(value:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                ]
                session.addOutput(output)
                
                if let width = output.videoSettings["Width"] as? Int,
                    let height = output.videoSettings["Height"] as? Int {
                    videoSize = CGSize(width: width, height: height)
                }

                if encode {
                    encoder = VTEncoder(width: Int32(videoSize.width),
                                        height: Int32(videoSize.height),
                                        bitrate: preferredBitrate)
                    encoder?.onEncoded = { status, infoFlags, sampleBuffer in
                        if let sampleBuffer = sampleBuffer, status == noErr {
                            self.onOutput(sampleBuffer)
                        }
                    }
                }
                dataDelegate?.client(client: self, didConfigureVideoSize: videoSize)
                output.setSampleBufferDelegate(self, queue: VideoCapture.captureQueue)

                self.input = input
                self.output = output
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    func reset(session:AVCaptureSession)
    {
        session.removeOutput(output)
        session.removeInput(input)
        
        stop()
    }
    
    func stop() {
        encoder?.close()
        encoder = nil
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    internal func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if encoder != nil {
            encoder!.encode(sampleBuffer: sampleBuffer)
        } else {
            onOutput(sampleBuffer)
        }
    }

    private func captureDevice(with position:AVCaptureDevicePosition) -> AVCaptureDevice? {
        var device: AVCaptureDevice? = nil
        
        if let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
            
            for d in devices {
                if (d as! AVCaptureDevice).position == position {
                    device = d as? AVCaptureDevice
                    break
                }
            }
        }
        return device
    }
    
    private var dataDelegate: AVCaptureClientDataDelegate? = nil
    func setDataDelegate(_ delegate: AVCaptureClientDataDelegate?)
    {
        dataDelegate = delegate
    }
    
    func set(options: [AVCaptureClientOptionKey])
    {
        self.options = options
        for option in options {
            switch(option) {
            case .encodeVideo(let enable):
                self.encode = enable
                break
                
            case .AVCaptureSessionPreset(let preset):
                preferredSessionPreset = preset
                break
                
            case .videoBitrate(let bitrate):
                preferredBitrate = bitrate
                break
                
            default:
                break
            }
        }
    }
    
    // MARK: VTEncoderVideoStreamer
    func onOutput(_ sampleBuffer: CMSampleBuffer)
    {
        dataDelegate?.client(client: self, output: sampleBuffer)
    }
    
}
