//
//  SpaceInvadersMachine.swift
//  Emulator8080
//
//  Created by Nitin Seshadri on 7/17/22.
//

import Foundation

// A Machine subclass that supports Space Invaders.
class SpaceInvadersMachine: Machine {
    
    public let framebufferStartLocation: Int = 0x2400
    public let framebufferEndLocation: Int = 0x3FFF
    
    private var cycleCounter: Int = 0
    private var interruptToggle: Bool = false
    
    // Hardware shift register
    private var shiftRegister: UInt16 = 0x0000
    private var shiftRegisterOffset: Int = 0
    
    private func inInstruction(port: UInt8) -> UInt8 {
        switch(port) {
        case 1:
            return 1
        case 2:
            return 0
        case 3:
            return UInt8((shiftRegister >> (8 - shiftRegisterOffset)) & 0x00FF)
        default:
            return 0
        }
    }
    
    private func outInstruction(port: UInt8, value: UInt8) {
        switch(port) {
        case 2:
            shiftRegisterOffset = Int(value & 0b00000111)
            break
        case 4:
            shiftRegister <<= 8
            shiftRegister &+= UInt16(value)
            break
        default:
            break
        }
    }
    
    override func execute() {
        
        if (cycleCounter > 1000000) {
            _ = cpu.interrupt(interruptToggle ? 1 : 2)
            
            cycleCounter = 0
            
            interruptToggle.toggle()
        }
        
        let code = [cpu.memory[Int(cpu.programCounter)], cpu.memory[Int(cpu.programCounter &+ 1)], cpu.memory[Int(cpu.programCounter &+ 2)]]
        let instruction = code[0]
        
        switch (instruction) {
        case 0xd3: // OUT D8
            outInstruction(port: code[1], value: cpu.registers.A)
            cpu.programCounter += 2
            break
        case 0xdb: // IN D8
            cpu.registers.A = inInstruction(port: code[1])
            cpu.programCounter += 2
            break
        default:
            super.execute()
            break
        }
        
        cycleCounter += 10
    }
    
}
