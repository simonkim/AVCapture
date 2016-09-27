//
//  AVCapture.swift
//  AVCapture
//
//  Created by Simon Kim on 2016. 9. 11..
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import AVFoundation

public enum AVCaptureClientSettingKey {
    case AVCaptureSessionPreset
    case bitrate
}

public protocol AVCaptureClient {
    
    var mediaType: CMMediaType { get }
    func configure(session:AVCaptureSession)
    func stop()
    func reset(session:AVCaptureSession)
    func set(value: Any, forKey key: AVCaptureClientSettingKey)
    func setDataDelegate(_ delegate: AVCaptureClientDataDelegate?)
}

public protocol AVCaptureClientDataDelegate {
    func client(client: AVCaptureClient, output sampleBuffer: CMSampleBuffer )
    func client(client: AVCaptureClient, didConfigureVideoSize videoSize: CGSize )
}

public class AVCaptureClientSimple: AVCaptureServiceClient {
    
    public var dataDelegate: AVCaptureClientDataDelegate? {
        didSet {
            for client in clients {
                client.setDataDelegate(dataDelegate)
            }
        }
    }
    
    public var videoCapture: AVCaptureClient {
        return clients[1]
    }

    private lazy var clients: [AVCaptureClient] = {
        return [AudioCapture(), VideoCapture()]
    }()
    
    public init() {
        
    }
    
    public func captureService(_ service: AVCaptureService, configure session: AVCaptureSession) {
        for client in clients {
            client.configure(session: session)
        }
    }
    
    public func captureService(_ service: AVCaptureService, reset session: AVCaptureSession) {
        for client in clients {
            client.reset(session: session)
        }
    }
    
    public func captureServiceDidStop(_ service: AVCaptureService) {
        for client in clients {
            client.stop()
        }
    }
}
