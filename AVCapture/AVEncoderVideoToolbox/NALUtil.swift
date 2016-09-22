//
//  NALUtil.swift
//  AVCapture
//
//  Created by Simon Kim on 2016. 9. 11..
//  Copyright © 2016 DZPub.com. All rights reserved.
//

import Foundation
import CoreMedia

enum NALUnitType: Int8 {
    case IDR = 5
    case SPS = 7
    case PPS = 8
}

class NALUtil {
    static func readNALUnitLength(at pointer: UnsafePointer<UInt8>, headerLength: Int) -> Int
    {
        var result: Int = 0
        
        for i in 0...(headerLength - 1) {
            result |= Int(pointer[i]) << (((headerLength - 1) - i) * 8)
        }
        return result
    }
}

extension CMBlockBuffer {
    
    /*
     * List of NAL Units without NALUnitHeader
     */
    public func NALUnits(headerLength: Int) -> [Data] {
        var totalLength: Int = 0
        var pointer:UnsafeMutablePointer<Int8>? = nil
        var dataArray: [Data] = []
        
        if noErr == CMBlockBufferGetDataPointer(self, 0, &totalLength, nil, &pointer) {
            while totalLength > Int(headerLength) {
                let unitLength = pointer!.withMemoryRebound(to: UInt8.self, capacity: totalLength) {
                    NALUtil.readNALUnitLength(at: $0, headerLength: Int(headerLength))
                }
                
                dataArray.append(Data(bytesNoCopy: pointer!.advanced(by: Int(headerLength)),
                                      count: unitLength,
                                      deallocator: .none))
                
                let nextOffset = headerLength + unitLength
                pointer = pointer!.advanced(by: nextOffset)
                totalLength -= Int(nextOffset)
            }
        }
        
        return dataArray
    }
    
}
