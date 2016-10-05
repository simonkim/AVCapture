//
//  AudioCapture.swift
//  AVCapture
//
//  Created by Simon Kim on 2016. 9. 11..
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import AVFoundation

class AudioCapture: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureClient {
    var mediaType: CMMediaType {
        return kCMMediaType_Audio
    }

    
    static var captureQueue: DispatchQueue = {
        return DispatchQueue(label:"audio-capture")
    }()
    
    private var input: AVCaptureDeviceInput? = nil
    private var output: AVCaptureAudioDataOutput? = nil
    private var options: [AVCaptureClientOptionKey] = []
    
    func configure(session: AVCaptureSession) {
        
        if let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeAudio),
            devices.count > 0 {
            do {
                let input = try AVCaptureDeviceInput(device: devices[0] as! AVCaptureDevice)
                session.addInput(input)
                
                let output = AVCaptureAudioDataOutput()
                output.setSampleBufferDelegate(self, queue: AudioCapture.captureQueue)
                session.addOutput(output)
            
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
    }
    
    internal func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        dataDelegate?.client(client: self, output: sampleBuffer)
    }
    
    func stop() {
        
    }

    
    private var dataDelegate: AVCaptureClientDataDelegate? = nil
    func setDataDelegate(_ delegate: AVCaptureClientDataDelegate?)
    {
        dataDelegate = delegate
    }
    
    func set(options: [AVCaptureClientOptionKey])
    {
        self.options = options
    }
    
}
