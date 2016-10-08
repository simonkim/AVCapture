//
//  AVCaptureService.swift
//  AVCapture
//
//  Created by Simon Kim on 9/22/16.
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import AVFoundation

public protocol AVCaptureServiceClient: class {
    func captureService(_ service: AVCaptureService, configure session: AVCaptureSession)
    func captureService(_ service: AVCaptureService, reset session: AVCaptureSession)
    func captureServiceDidStop(_ service: AVCaptureService)
}

public class AVCaptureService {
    public var serviceClient: AVCaptureServiceClient {
        return _serviceClient
    }
    
    public var previewLayer: AVCaptureVideoPreviewLayer? {
        return _preview
    }
    
    /// AVCaptureSession's masterClock property
    public var masterClock: CMClock {
        return _session.masterClock
    }
    
    private lazy var _session: AVCaptureSession = {
       return AVCaptureSession()
    }()
    
    private var _preview: AVCaptureVideoPreviewLayer? = nil
    
    private var _sessionStarted: Bool = false
    
    private var _serviceClient: AVCaptureServiceClient
    
    public init(client: AVCaptureServiceClient)
    {
        _serviceClient = client
    }
    
    // MARK:
    func configure(session: AVCaptureSession) -> Bool
    {
        var result = false
        session.beginConfiguration()
        serviceClient.captureService(self, configure: session)
        if session.inputs.count > 0 && session.outputs.count > 0 {
            result = true
            session.commitConfiguration()
        }
        return result
    }
    
    // MARK: API
    public func start(configured:((Bool)->Void)? = nil) -> Bool
    {
        if _sessionStarted {
            return false
        }
        
        let succeed = configure(session: _session)
        configured?(succeed)
        
        if succeed {
            _session.startRunning()
            
            if _preview == nil {
                _preview = AVCaptureVideoPreviewLayer.init(session: _session)
                _preview?.videoGravity = AVLayerVideoGravityResizeAspect
            }
            
            _sessionStarted = true
        }
        
        return succeed
        
    }
    
    public func reconfigure()
    {
        serviceClient.captureService(self, reset: _session)
        _ = configure(session: _session)
    }
    
    public func stop()
    {
        if _sessionStarted {
            
            serviceClient.captureService(self, reset: _session)
            
            for input in _session.inputs {
                _session.removeInput(input as! AVCaptureInput)
            }
            
            for output in _session.outputs {
                _session.removeOutput(output as! AVCaptureOutput)
            }
            
            _preview?.removeFromSuperlayer()
            _session.stopRunning()
            
            _sessionStarted = false            
        }
    }
}
