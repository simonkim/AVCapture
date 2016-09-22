//
//  BitrateMeasure.swift
//  AVCapture
//
//  Created by Simon Kim on 9/22/16.
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation

public struct BitrateMeasure {
    var firstPTS: Double = -1
    public var bps: Int = 0
    var bytes: Int = 0
    
    public init() {
        
    }
    
    public mutating func measure(dataArray:[Data], pts:Double) -> Int {
        if firstPTS < 0 {
            firstPTS = pts
        } else if (pts - self.firstPTS) < 1 {
            bytes += dataArray.reduce(0) { $0 + $1.count }
            bps = self.bytes * 8
        }
        
        return self.bps
    }
}
