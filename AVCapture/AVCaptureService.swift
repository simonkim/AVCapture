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
    func configure(session: AVCaptureSession)
    {
        session.beginConfiguration()
        serviceClient.captureService(self, configure: session)
        session.commitConfiguration()
    }
    
    // MARK: API
    public func start(configured:((Bool)->Void)? = nil)
    {
        if _sessionStarted {
            return
        }
        configure(session: _session)
        configured?(true)
        _session.startRunning()
        
        _preview = AVCaptureVideoPreviewLayer.init(session: _session)
        _preview?.videoGravity = AVLayerVideoGravityResizeAspect
        
        _sessionStarted = true
        
    }
    
    public func reconfigure()
    {
        serviceClient.captureService(self, reset: _session)
        configure(session: _session)
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
            
            _session.stopRunning()
            
        }
    }
    
    
}
