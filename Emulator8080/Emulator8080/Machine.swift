//
//  Machine.swift
//  Emulator8080
//
//  Created by Nitin Seshadri on 7/14/22.
//

import Foundation

class Machine: NSObject {
    
    public var cpu: Intel8080!
    
    // The size of the memory, in 8-bit words.
    public var memorySize: Int {
        get {
            return cpu.memory.count
        }
    }
    
    // Initialize a new machine.
    // - memorySize: The memory size in 8-bit words. The default is 64*1024 words, or 64K bytes.
    init(memorySize: Int = 64*1024) {
        super.init()
        
        cpu = Intel8080(memorySize: memorySize)
    }
    
    // Map bytes into memory.
    // Returns the memory location right after the mapped bytes,
    // which you can feed into another mapIntoMemory invocation to map multiple sequences next to each other in memory.
    public func mapIntoMemory(bytes: [UInt8], startingAt location: Int) -> Int {
        var pointer: Int = location
        
        for byte in bytes {
            cpu.memory[pointer] = byte
            pointer += 1
        }
        
        return pointer
    }
    
    // Execute the instruction at the program counter.
    public func execute() {
        cpu.execute()
    }
}
