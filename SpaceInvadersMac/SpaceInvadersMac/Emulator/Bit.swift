//
//  Bit.swift
//  Emulator8080
//
//  Created by Nitin Seshadri on 7/14/22.
//

import Foundation

extension UInt8 {
    
    func bits() -> [Bool] {
        var byte = self
        var bits = [Bool](repeating: false, count: 8)
        for i in 0..<8 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = true
            }

            byte >>= 1
        }

        return bits
    }
    
    func msb() -> UInt8 {
        return (self & 0b10000000) >> 7
    }
    
    func msb() -> UInt16 {
        return UInt16((self & 0b10000000) >> 7)
    }
    
    func msb() -> Bool {
        return ((self & 0b10000000) >> 7) == 1 ? true : false
    }
    
    func lsb() -> UInt8 {
        return (self & 0b00000001)
    }
    
    func lsb() -> UInt16 {
        return UInt16(self & 0b00000001)
    }
    
    func lsb() -> Bool {
        return (self & 0b00000001) == 1 ? true : false
    }
}
