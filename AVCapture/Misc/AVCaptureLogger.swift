//
//  AVCaptureLogger.swift
//  AVCapture
//
//  Created by Simon Kim on 10/19/16.
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation

protocol AVCaptureLogger {
    func logD(_ message: String)
    func logE(_ message: String)
    func log(_ level: LogSettings.Level, message: String)
}

struct LogSettings {
    var level: Level = .information

    var logEnabled: Bool {
        return Level.information.rawValue < level.rawValue
    }
    
    var errEnabled: Bool {
        return Level.disabled.rawValue < level.rawValue
    }
    
    enum Level: Int {
        case disabled = -1
        case error = 0
        case warning
        case information
        case debug
        case verbose
        
        static var strings: [String] = [
            "ERR", "WRN", "INF", "DBG", "VRB"
        ]
        
        var string: String {
            var result = "   "
            if self.rawValue >= 0 {
                result = Level.strings[self.rawValue]
            }
            return result
        }
    }
}

class LogConfig {
    static var settings: LogSettings = {
        return LogSettings()
    }()
    
}

extension AVCaptureLogger {
    
    internal func logD(_ message: String)
    {
        log(.debug, message: message)
    }
    
    internal func logE(_ message: String) {
        log(.error, message: message)
    }
    
    internal func log(_ level: LogSettings.Level, message: String)
    {
        if LogConfig.settings.level.rawValue < level.rawValue {
            return
        }
        print("\(level.string): \(message)")
    }
    
}
