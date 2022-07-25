//
//  Intel8080.swift
//  Emulator8080
//
//  Created by Nitin Seshadri on 7/14/22.
//

import Foundation

class Intel8080: NSObject {

    public struct Registers {
        // Registers
        var A: UInt8 = 0x00
        var B: UInt8 = 0x00
        var C: UInt8 = 0x00
        var D: UInt8 = 0x00
        var E: UInt8 = 0x00
        var H: UInt8 = 0x00
        var L: UInt8 = 0x00
        
        var BC: UInt16 {
            get {
                return (UInt16(B) << 8) + UInt16(C)
            }
            set {
                B = UInt8(newValue >> 8 & 0x00FF)
                C = UInt8(newValue & 0x00FF)
            }
        }
        var DE: UInt16 {
            get {
                return (UInt16(D) << 8) + UInt16(E)
            }
            set {
                D = UInt8(newValue >> 8 & 0x00FF)
                E = UInt8(newValue & 0x00FF)
            }
        }
        var HL: UInt16 {
            get {
                return (UInt16(H) << 8) + UInt16(L)
            }
            set {
                H = UInt8(newValue >> 8 & 0x00FF)
                L = UInt8(newValue & 0x00FF)
            }
        }
    }
    
    public struct Flags {
        var zero: Bool = false // True if result is zero
        var sign: Bool = false // True if MSB (bit 7) of result is 1 (true = negative)
        var parity: Bool = false // True if answer has even parity, false when odd
        var carry: Bool = false
        var auxiliaryCarry: Bool = false // Used in BCD math
        
        var PSW: UInt8 {
            get {
                let PSWarray = [sign, zero, false, auxiliaryCarry, false, parity, true, carry]
                var PSWbyte: UInt8 = 0b00000000
                for flag in PSWarray {
                    PSWbyte &<<= 1
                    let bit: UInt8 = flag ? 1 : 0
                    PSWbyte += bit
                }
                return PSWbyte
            }
            set {
                let PSWbits = newValue.bits()
                sign = PSWbits[7]
                zero = PSWbits[6]
                auxiliaryCarry = PSWbits[4]
                parity = PSWbits[2]
                carry = PSWbits[0]
            }
        }
    }
    
    public var registers = Registers()
    
    public var flags = Flags()
    
    public var stackPointer: UInt16 = 0x00FF
    public var programCounter: UInt16 = 0x0000
    
    public var interruptsEnabled: Bool = false
    
    public var memory: [UInt8] = []
    
    public var registerM: UInt8 {
        // Note: This needs to be out here since it represents a memory location
        get {
            let value = memory[Int(registers.HL)]
            return value
        } set {
            memory[Int(registers.HL)] = newValue
        }
    }
    
    public var halted: Bool = false {
        didSet {
            if (halted) {
                print("\nCPU halted")
                print(interruptsEnabled ? "Interrupts enabled" : "Interrupts disabled")
                printState(disassemble: false)
            }
        }
    }
    
    // Initialize a new 8080 CPU.
    // - memorySize: The memory size in 8-bit words. The default is 64*1024 words, or 64K bytes.
    init(memorySize: Int = 64*1024) {
        super.init()
        
        memory = [UInt8](repeating: 0x00, count: memorySize)
    }
    
    private func updateZSPACFlags(for result: UInt8, updateAuxiliaryCarry: Bool = true) {
        let bits = result.bits()
        
        // Zero flag
        if (result == 0x00) {
            flags.zero = true
        } else {
            flags.zero = false
        }
        
        // Sign flag
        if (bits[7] == true) {
            flags.sign = true
        } else {
            flags.sign = false
        }
        
        // Parity flag
        var onesCount: Int {
            var count = 0
            for bit in bits {
                if bit == true {
                    count += 1
                }
            }
            return count
        }
        if (onesCount % 2 == 0) {
            flags.parity = true
        } else {
            flags.parity = false
        }
        
        if (updateAuxiliaryCarry) {
            // Auxiliary carry flag
            if (result > 0x0F) {
                flags.auxiliaryCarry = true
            } else {
                flags.auxiliaryCarry = false
            }
        }
    }
    
    private func updateCarryFlag(for result: UInt16, allowReset: Bool = true) {
         
        // Carry flag
        if (result > 0xFF) {
            flags.carry = true
        } else {
            if (allowReset) {
                flags.carry = false
            }
        }
    }
    
    private func getHighByte(of value: UInt16) -> UInt8 {
        let highByte = UInt8(value >> 8 & 0x00FF)
        
        return highByte
    }
    
    private func getLowerByte(of value: UInt16) -> UInt8 {
        let lowerByte = UInt8(value & 0x00FF)
        
        return lowerByte
    }
    
    private func getAddress(highByte: UInt8, lowByte: UInt8) -> UInt16 {
        return (UInt16(highByte) << 8) + UInt16(lowByte)
    }
    
    
    private func pushOntoStack(_ value: UInt8) {
        memory[Int(stackPointer &- 1)] = value
        stackPointer &-= 1
    }
    
    private func pushOntoStack(_ value: UInt16) {
        //print(String(format: "Stack was: 0x%04x", getAddressFromStack()))
        pushOntoStack(getHighByte(of: value))
        pushOntoStack(getLowerByte(of: value))
        //print(String(format: "Pushed address onto stack: 0x%04x", getAddressFromStack()))
    }
    
    private func popByteFromStack() -> UInt8 {
        let byte = memory[Int(stackPointer)]
        stackPointer &+= 1
        return byte
    }
    
    private func popAddressFromStack() -> UInt16 {
        let lowByte = popByteFromStack()
        let highByte = popByteFromStack() // Note: order matters here
        let address = getAddress(highByte: highByte, lowByte: lowByte)
        //print(String(format: "Popped address from stack: 0x%04x", address))
        return address
    }
    
    // FOR DEBUG USE ONLY
    private func getAddressFromStack() -> UInt16 {
        let lowByte = memory[Int(stackPointer)]
        let highByte = memory[Int(stackPointer+1)]
        let address = getAddress(highByte: highByte, lowByte: lowByte)
        return address
    }
    
    private func registerKeyPathForThreeBitCode(_ code: UInt8) -> ReferenceWritableKeyPath<Intel8080, UInt8> {
        switch (code) {
        case 0b000:
            return \Intel8080.registers.B
        case 0b001:
            return \Intel8080.registers.C
        case 0b010:
            return \Intel8080.registers.D
        case 0b011:
            return \Intel8080.registers.E
        case 0b100:
            return \Intel8080.registers.H
        case 0b101:
            return \Intel8080.registers.L
        case 0b110:
            return \Intel8080.registerM
        case 0b111:
            return \Intel8080.registers.A
        default:
            return \Intel8080.registers.B
        }
    }
    
    private func jumpInstruction(_ address: UInt16) {
        programCounter = address
    }
    
    private func callInstruction(_ address: UInt16) {
        
        if (address == 0x0689) { // CP/M CPUDIAG CPUER routine
            print("CPUER called")
        }
        
        let returnAddress = programCounter &+ 3
        pushOntoStack(returnAddress)
        jumpInstruction(address)
    }
    
    private func returnInstruction() {
        programCounter = popAddressFromStack()
    }

    private func unimplementedInstruction(_ instruction: UInt8) {
        print(String(format: "Warning: Unimplemented instruction 0x%02x", instruction))
    }
    
    public func printState(disassemble: Bool = true) {
        print(String(format: "PC: 0x%04x", programCounter))
        if (disassemble) {
            _ = disassemble8080Opcode(bytes: memory, pc: Int(programCounter))
        }
        print(registers)
        print(flags)
        print(String(format: "SP: 0x%04x: 0x%04x", stackPointer, getAddressFromStack()))
    }
    
    // This is identical to calling RST n. No interrupt will be sent if interrupts are disabled.
    // Returns true if the interrupt was sent, false if not.
    public func interrupt(_ interruptNumber: Int) -> Bool {
        if (interruptsEnabled) {
            callInstruction(8 * UInt16(interruptNumber))
            interruptsEnabled = false
            halted = false
            return true
        } else {
            return false
        }
    }

    func execute() {
        if (halted) {
            usleep(1000000)
            return
        }
        
        let code = [memory[Int(programCounter)], memory[Int(programCounter &+ 1)], memory[Int(programCounter &+ 2)]]
        let instruction = code[0]
        
        var opbytes = 1
        
        switch(instruction) {
            
        case 0x00:
            // NOP
            break
        case 0x01: // LXI B,D16
            registers.B = code[2]
            registers.C = code[1]
            opbytes = 3
            break
        case 0x02: // STAX B
            memory[Int(registers.BC)] = registers.A
            break
        case 0x03: // INX B
            registers.BC &+= 1
            break
        case 0x04: // INR B
            registers.B &+= 1
            updateZSPACFlags(for: registers.B)
            break
        case 0x05: // DCR B
            registers.B &-= 1
            updateZSPACFlags(for: registers.B)
            break
        case 0x06: // MVI B,D8
            registers.B = code[1]
            opbytes = 2
            break
        case 0x07: // RLC
            var rotator = UInt16(registers.A)
            rotator = rotator << 1
            rotator &+= registers.A.msb() // bit 0 = prev bit 7
            flags.carry = registers.A.msb() // CY = prev bit 7
            registers.A = getLowerByte(of: rotator)
            break
        case 0x08:
            // NOP
            break
        case 0x09: // DAD B
            registers.HL = registers.HL &+ registers.BC
            updateCarryFlag(for: registers.HL)
            break
        case 0x0a: // LDAX B
            registers.A = memory[Int(registers.BC)]
            break
        case 0x0b: // DCX B
            registers.BC &-= 1
            break
        case 0x0c: // INR C
            registers.C &+= 1
            updateZSPACFlags(for: registers.C)
            break
        case 0x0d: // DCR C
            registers.C &-= 1
            updateZSPACFlags(for: registers.C)
            break
        case 0x0e: // MVI C, D8
            registers.C = code[1]
            opbytes = 2
            break
        case 0x0f: // RRC
            var rotator = UInt16(registers.A)
            rotator = rotator >> 1
            rotator &+= (registers.A.lsb() << 7) // bit 7 = prev bit 0
            flags.carry = registers.A.lsb() // CY = prev bit 0
            registers.A = getLowerByte(of: rotator)
            break
            
            
        case 0x10:
            // NOP
            break
        case 0x11: // LXI D,D16
            registers.D = code[2]
            registers.E = code[1]
            opbytes = 3
            break
        case 0x12: // STAX D
            memory[Int(registers.DE)] = registers.A
            break
        case 0x13: // INX D
            registers.DE &+= 1
            break
        case 0x14: // INR D
            registers.D &+= 1
            updateZSPACFlags(for: registers.D)
            break
        case 0x15: // DCR D
            registers.D &-= 1
            updateZSPACFlags(for: registers.D)
            break
        case 0x16: // MVI D,D8
            registers.D = code[1]
            opbytes = 2
            break
        case 0x17: // RAL
            var rotator = UInt16(registers.A)
            rotator = rotator << 1
            rotator &+= (flags.carry ? 1 : 0) // bit 0 = prev CY
            flags.carry = registers.A.msb() // CY = prev bit 7
            registers.A = getLowerByte(of: rotator)
            break
        case 0x18:
            // NOP
            break
        case 0x19: // DAD D
            registers.HL = registers.HL &+ registers.DE
            updateCarryFlag(for: registers.HL)
            break
        case 0x1a: // LDAX D
            registers.A = memory[Int(registers.DE)]
            break
        case 0x1b: // DCX D
            registers.DE &-= 1
            break
        case 0x1c: // INR E
            registers.E &+= 1
            updateZSPACFlags(for: registers.E)
            break
        case 0x1d:
            registers.E &-= 1
            updateZSPACFlags(for: registers.E)
            break
        case 0x1e: // MVI E,D8
            registers.E = code[1]
            opbytes = 2
            break
        case 0x1f: // RAR
            var rotator = UInt16(registers.A)
            rotator = rotator >> 1
            rotator &+= (registers.A.msb() << 7) // bit 7 = prev bit 7
            flags.carry = registers.A.lsb() // CY = prev bit 0
            registers.A = getLowerByte(of: rotator)
            break
            
            
        case 0x20: // RIM on 8085
            // NOP
            break
        case 0x21: // LXI H,D16
            registers.H = code[2]
            registers.L = code[1]
            opbytes = 3
            break
        case 0x22: // SHLD adr
            let address = getAddress(highByte: code[2], lowByte: code[1])
            memory[Int(address)] = registers.L
            memory[Int(address+1)] = registers.H
            opbytes = 3
            break
        case 0x23: // INX H
            registers.HL &+= 1
            break
        case 0x24: // INR H
            registers.H &+= 1
            updateZSPACFlags(for: registers.H)
            break
        case 0x25: // DCR H
            registers.H &-= 1
            updateZSPACFlags(for: registers.H)
            break
        case 0x26: // MVI H,D8
            registers.H = code[1]
            opbytes = 2
            break
        case 0x27: // DAA
            let leastFour = registers.A & 0b00001111
            if (leastFour > 9 || flags.auxiliaryCarry) {
                registers.A &+= 6
            }
            updateZSPACFlags(for: registers.A)
            let mostFour = (registers.A & 0b11110000) >> 4
            var result = UInt16(registers.A)
            if (mostFour > 9 || flags.carry) {
                result &+= 0x60
            }
            updateCarryFlag(for: result, allowReset: false) // Don't allow the Carry flag to be reset
            registers.A = getLowerByte(of: result)
            updateZSPACFlags(for: registers.A)
            break
        case 0x28:
            // NOP
            break
        case 0x29: // DAD H
            registers.HL = registers.HL &+ registers.HL
            updateCarryFlag(for: registers.HL)
            break
        case 0x2a: // LHLD adr
            let address = getAddress(highByte: code[2], lowByte: code[1])
            registers.L = memory[Int(address)]
            registers.H = memory[Int(address+1)]
            opbytes = 3
            break
        case 0x2b: // DCX H
            registers.HL &-= 1
            break
        case 0x2c: // INR L
            registers.L &+= 1
            updateZSPACFlags(for: registers.L)
            break
        case 0x2d: // DCR L
            registers.L &-= 1
            updateZSPACFlags(for: registers.L)
            break
        case 0x2e: // MVI L,D8
            registers.L = code[1]
            opbytes = 2
            break
        case 0x2f: // CMA
            registers.A = ~registers.A
            break
            
            
        case 0x30: // SIM on 8085
            // NOP
            break
        case 0x31: // LXI SP,D16
            stackPointer = (UInt16(code[2]) << 8) + UInt16(code[1])
            opbytes = 3
            break
        case 0x32: // STA adr
            let address = getAddress(highByte: code[2], lowByte: code[1])
            memory[Int(address)] = registers.A
            opbytes = 3
            break
        case 0x33: // INX SP
            stackPointer &+= 1
            break
        case 0x34: // INR M
            registerM &+= 1
            updateZSPACFlags(for:  registerM)
            break
        case 0x35: // DCR M
            registerM &-= 1
            updateZSPACFlags(for:  registerM)
            break
        case 0x36: // MVI M,D8
            registerM = code[1]
            opbytes = 2
            break
        case 0x37: // STC
            flags.carry = true
            break
        case 0x38:
            // NOP
            break
        case 0x39: // DAD SP
            registers.HL = registers.HL &+ stackPointer
            updateCarryFlag(for: registers.HL)
            break
        case 0x3a: // LDA adr
            let address = getAddress(highByte: code[2], lowByte: code[1])
            registers.A = memory[Int(address)]
            opbytes = 3
            break
        case 0x3b: // DCX SP
            stackPointer &-= 1
            break
        case 0x3c: // INR A
            registers.A &+= 1
            updateZSPACFlags(for: registers.A)
            break
        case 0x3d: // DCR A
            registers.A &-= 1
            updateZSPACFlags(for: registers.A)
            break
        case 0x3e: // MVI A,D8
            registers.A = code[1]
            opbytes = 2
            break
        case 0x3f: // CMC
            flags.carry = !flags.carry
            break
            
        // 0x40 - 0x7f: MOV instructions
        // Except for HLT, these are handled separately. See the default case.
        
        case 0x76: // HLT
            halted = true
            break
            
        // 0x80 - 0xbf: ALU instructions
        // These are handled separately. See the default case.
            // 0x80 - 0x87: ADD
            // 0x88 - 0x8f: ADC
            // 0x90 - 0x97: SUB
            // 0x98 - 0x9f: SBC
            // 0xa0 - 0xa7: ANA
            // 0xa8 - 0xaf: XRA
            // 0xb0 - 0xb7: ORA
            // 0xb8 - 0xbf: CMP
            
        case 0xc0: // RNZ
            if !flags.zero {
                returnInstruction()
                opbytes = 0
            }
            break
        case 0xc1: // POP B
            registers.BC = popAddressFromStack()
            break
        case 0xc2: // JNZ addr
            if !flags.zero {
                jumpInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xc3: // JMP addr
            jumpInstruction(getAddress(highByte: code[2], lowByte: code[1]))
            opbytes = 0
            
            
            if (getAddress(highByte: code[2], lowByte: code[1]) == 0x0000) { // CP/M Warm Boot
                halted = true
            }
            
            break
        case 0xc4: // CNZ addr
            if !flags.zero {
                callInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xc5: // PUSH B
            pushOntoStack(registers.BC)
            break
        case 0xc6: // ADI D8
            let result = UInt16(registers.A) &+ UInt16(code[1])
            updateCarryFlag(for: result)
            registers.A = getLowerByte(of: result)
            updateZSPACFlags(for: registers.A)
            opbytes = 2
            break
        case 0xc7: // RST 0
            callInstruction(0x0000)
            opbytes = 0
            break
        case 0xc8: // RZ
            if flags.zero {
                returnInstruction()
                opbytes = 0
            }
            break
        case 0xc9: // RET
            returnInstruction()
            opbytes = 0
            break
        case 0xca: // JZ addr
            if flags.zero {
                jumpInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xcb:
            // NOP
            break
        case 0xcc: // CZ addr
            if flags.zero {
                callInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xcd: // CALL adr
            
            switch (getAddress(highByte: code[2], lowByte: code[1])) {
            case 0x0005:
                if (registers.C == 9) { // CP/M BDOS String Output (BDOS function 9)
                    let charIndices = memory.indices.filter { $0 >= (registers.DE) }
                    let charbytes = charIndices.map { memory[$0] }
                    for byte in charbytes {
                        let chardata = Data([byte])
                        let charstring = String(data: chardata, encoding: .utf8) ?? "$"
                        if (charstring != "$") {
                            print(charstring, terminator: "")
                        } else {
                            break
                        }
                    }
                } else if (registers.C == 2) { // CP/M BDOS Console Output (BDOS function 2)
                    let chardata = Data([registers.E])
                    let charstring = String(data: chardata, encoding: .utf8) ?? "$"
                    if (charstring != "$") {
                        print(charstring, terminator: "")
                    } else {
                        break
                    }
                }
                opbytes = 3
                break
            default:
                callInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            }
            
            //callInstruction(getAddress(highByte: code[2], lowByte: code[1]))
            //opbytes = 0
            break
        case 0xce: // ACI D8
            let result = UInt16(registers.A) &+ UInt16(code[1]) &+ (flags.carry ? 1 : 0)
            updateCarryFlag(for: result)
            registers.A = getLowerByte(of: result)
            updateZSPACFlags(for: registers.A)
            opbytes = 2
            break
        case 0xcf: // RST 1
            callInstruction(0x0008)
            opbytes = 0
            break
            
        
        case 0xd0: // RNC
            if !flags.carry {
                returnInstruction()
                opbytes = 0
            }
            break
        case 0xd1: // POP D
            registers.DE = popAddressFromStack()
            break
        case 0xd2: // JNC addr
            if !flags.carry {
                jumpInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xd3: // OUT D8
            unimplementedInstruction(instruction)
            opbytes = 2
            break
        case 0xd4: // CNC addr
            if !flags.carry {
                callInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xd5: // PUSH D
            pushOntoStack(registers.DE)
            break
        case 0xd6: // SUI D8
            let result = UInt16(registers.A) &- UInt16(code[1])
            updateCarryFlag(for: result)
            registers.A = getLowerByte(of: result)
            updateZSPACFlags(for: registers.A)
            opbytes = 2
            break
        case 0xd7: // RST 2
            callInstruction(0x0010)
            opbytes = 0
            break
        case 0xd8: // RC
            if flags.carry {
                returnInstruction()
                opbytes = 0
            }
            break
        case 0xd9:
            // NOP
            break
        case 0xda: // JC addr
            if flags.carry {
                jumpInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xdb: // IN D8
            unimplementedInstruction(instruction)
            opbytes = 2
            break
        case 0xdc: // CC addr
            if flags.carry {
                callInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xdd:
            // NOP
            break
        case 0xde: // SBI D8
            let result = UInt16(registers.A) &- UInt16(code[1]) &- (flags.carry ? 1 : 0)
            updateCarryFlag(for: result)
            registers.A = getLowerByte(of: result)
            updateZSPACFlags(for: registers.A)
            opbytes = 2
            break
        case 0xdf: // RST 3
            callInstruction(0x0018)
            opbytes = 0
            break
            
        case 0xe0: // RPO
            if !flags.parity {
                returnInstruction()
                opbytes = 0
            }
            break
        case 0xe1: // POP H
            registers.HL = popAddressFromStack()
            break
        case 0xe2: // JPO
            if !flags.parity {
                jumpInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xe3: // XTHL
            let oldSPaddr = popAddressFromStack()
            pushOntoStack(registers.HL)
            registers.HL = oldSPaddr
            break
        case 0xe4: // CPO
            if !flags.parity {
                callInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xe5: // PUSH H
            pushOntoStack(registers.HL)
            break
        case 0xe6: // ANI D8
            registers.A = registers.A & code[1]
            updateZSPACFlags(for: registers.A)
            opbytes = 2
            break
        case 0xe7: // RST 4
            callInstruction(0x0020)
            opbytes = 0
            break
        case 0xe8: // RPE
            if flags.parity {
                returnInstruction()
                opbytes = 0
            }
            break
        case 0xe9: // PCHL
            programCounter = registers.HL
            opbytes = 0
            break
        case 0xea: // JPE
            if flags.parity {
                jumpInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xeb: // XCHG
            // H <-> D
            let oldH = registers.H
            registers.H = registers.D
            registers.D = oldH
            // L <-> E
            let oldL = registers.L
            registers.L = registers.E
            registers.E = oldL
            break
        case 0xec: // CPE
            if flags.parity {
                callInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xed:
            // NOP
            break
        case 0xee: // XRI D8
            registers.A = registers.A ^ code[1]
            updateZSPACFlags(for: registers.A)
            opbytes = 2
            break
        case 0xef: // RST 5
            callInstruction(0x0028)
            opbytes = 0
            break
            
        case 0xf0: // RP
            if !flags.sign {
                returnInstruction()
                opbytes = 0
            }
            break
        case 0xf1: // POP PSW
            flags.PSW = popByteFromStack()
            registers.A = popByteFromStack()
            break
        case 0xf2: // JP
            if !flags.sign {
                jumpInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xf3: // DI
            interruptsEnabled = false
            break
        case 0xf4: // CP
            if !flags.sign {
                callInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xf5: // PUSH PSW
            pushOntoStack(registers.A)
            pushOntoStack(flags.PSW)
            break
        case 0xf6: // ORI D8
            registers.A = registers.A | code[1]
            updateZSPACFlags(for: registers.A)
            opbytes = 2
            break
        case 0xf7: // RST 6
            callInstruction(0x0030)
            opbytes = 0
            break
        case 0xf8: // RM
            if flags.sign {
                returnInstruction()
                opbytes = 0
            }
            break
        case 0xf9: // SPHL
            stackPointer = registers.HL
            break
        case 0xfa: // JM
            if flags.sign {
                jumpInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xfb: // EI
            interruptsEnabled = true
            break
        case 0xfc: // CM
            if flags.sign {
                callInstruction(getAddress(highByte: code[2], lowByte: code[1]))
                opbytes = 0
            } else {
                opbytes = 3
            }
            break
        case 0xfd:
            // NOP
            break
        case 0xfe: // CPI D8
            let result = UInt16(registers.A) &- UInt16(code[1])
            updateCarryFlag(for: result)
            let resultLower = getLowerByte(of: result) // Note: This instruction does not modify A
            updateZSPACFlags(for: resultLower)
            opbytes = 2
            break
        case 0xff: // RST 7
            callInstruction(0x0038)
            opbytes = 0
            break
        
            
        default:
            if (0x40...0x7f).contains(instruction) { // MOV
                // Note: HLT (0x76) is already accounted for above, so we don't need to worry about it here.
                let src = instruction & 0b00000111
                let dst = (instruction & 0b00111000) >> 3
                let srcKeyPath = registerKeyPathForThreeBitCode(src)
                let dstKeyPath = registerKeyPathForThreeBitCode(dst)
                self[keyPath: dstKeyPath] = self[keyPath: srcKeyPath]
            } else if (0x80...0xbf).contains(instruction) { // ALU instructions
                let op = (instruction & 0b00111000) >> 3
                let reg = instruction & 0b00000111
                let regKeyPath = registerKeyPathForThreeBitCode(reg)
                
                switch(op) {
                case 0b000: // ADD
                    let result = UInt16(registers.A) &+ UInt16(self[keyPath: regKeyPath])
                    updateCarryFlag(for: result)
                    registers.A = getLowerByte(of: result)
                    updateZSPACFlags(for: registers.A)
                    break
                case 0b001: // ADC
                    let result = UInt16(registers.A) &+ UInt16(self[keyPath: regKeyPath]) &+ (flags.carry ? 1 : 0)
                    updateCarryFlag(for: result)
                    registers.A = getLowerByte(of: result)
                    updateZSPACFlags(for: registers.A)
                    break
                case 0b010: // SUB
                    let result = UInt16(registers.A) &- UInt16(self[keyPath: regKeyPath])
                    updateCarryFlag(for: result)
                    registers.A = getLowerByte(of: result)
                    updateZSPACFlags(for: registers.A)
                    break
                case 0b011: // SBB
                    let result = UInt16(registers.A) &- UInt16(self[keyPath: regKeyPath]) &- (flags.carry ? 1 : 0)
                    updateCarryFlag(for: result)
                    registers.A = getLowerByte(of: result)
                    updateZSPACFlags(for: registers.A)
                    break
                case 0b100: // ANA
                    registers.A = registers.A & self[keyPath: regKeyPath]
                    updateZSPACFlags(for: registers.A, updateAuxiliaryCarry: false)
                    break
                case 0b101: // XRA
                    registers.A = registers.A ^ self[keyPath: regKeyPath]
                    updateZSPACFlags(for: registers.A, updateAuxiliaryCarry: false)
                    break
                case 0b110: // ORA
                    registers.A = registers.A | self[keyPath: regKeyPath]
                    updateZSPACFlags(for: registers.A, updateAuxiliaryCarry: false)
                    break
                case 0b111: // CMP
                    let result = UInt16(registers.A) &- UInt16(self[keyPath: regKeyPath])
                    updateCarryFlag(for: result)
                    let resultLower = getLowerByte(of: result) // Note: This instruction does not modify A
                    updateZSPACFlags(for: resultLower)
                    break
                default:
                    unimplementedInstruction(instruction)
                }
            } else {
                unimplementedInstruction(instruction)
            }
        }
        
        //printState(disassemble: false)
        
        programCounter &+= UInt16(opbytes)

    }
    
}
