//
//  Disassembler.swift
//  Emulator8080
//
//  Created by Nitin Seshadri on 7/12/22.
//

import Foundation

func disassemble8080Opcode(bytes: [UInt8], pc: Int) -> Int {
    let codeIndices = bytes.indices.filter { $0 >= pc }
    let code = codeIndices.map { bytes[$0] }
    let instr = code[0]
    
    print("   ", terminator: "") // Indent the line
    
    var opbytes = 1
    print(String(format: "%04x ", pc), terminator: "")
    
    // Disassembly stuff here
    
    switch(instr) {
        
    case 0x00:
        print("NOP", terminator: "")
        break
    case 0x01:
        print(String(format: "LXI    B,#$%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0x02:
        print("STAX   B", terminator: "")
        break
    case 0x03:
        print("INX    B", terminator: "")
        break
    case 0x04:
        print("INR    B", terminator: "")
        break
    case 0x05:
        print("DCR    B", terminator: "")
        break
    case 0x06:
        print(String(format: "MVI    B,#$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0x07:
        print("RLC", terminator: "")
        break
    case 0x08:
        print("NOP", terminator: "")
        break
    case 0x09:
        print("DAD    B", terminator: "")
        break
    case 0x0a:
        print("LDAX    B", terminator: "")
        break
    case 0x0b:
        print("DCX    B", terminator: "")
        break
    case 0x0c:
        print("INR    C", terminator: "")
        break
    case 0x0d:
        print("DCR    C", terminator: "")
        break
    case 0x0e:
        print(String(format: "MVI    C,#$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0x0f:
        print("RRC", terminator: "")
        break
        
        
    case 0x10:
        print("NOP", terminator: "")
        break
    case 0x11:
        print(String(format: "LXI    D,#$%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0x12:
        print("STAX   D", terminator: "")
        break
    case 0x13:
        print("INX    D", terminator: "")
        break
    case 0x14:
        print("INR    D", terminator: "")
        break
    case 0x15:
        print("DCR    D", terminator: "")
        break
    case 0x16:
        print(String(format: "MVI    D,#$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0x17:
        print("RAL", terminator: "")
        break
    case 0x18:
        print("NOP", terminator: "")
        break
    case 0x19:
        print("DAD    D", terminator: "")
        break
    case 0x1a:
        print("LDAX    D", terminator: "")
        break
    case 0x1b:
        print("DCX    D", terminator: "")
        break
    case 0x1c:
        print("INR    E", terminator: "")
        break
    case 0x1d:
        print("DCR    E", terminator: "")
        break
    case 0x1e:
        print(String(format: "MVI    E,#$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0x1f:
        print("RAR", terminator: "")
        break
        
        
    case 0x20:
        print("RIM", terminator: "")
        break
    case 0x21:
        print(String(format: "LXI    H,#$%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0x22:
        print(String(format: "SHLD    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0x23:
        print("INX    H", terminator: "")
        break
    case 0x24:
        print("INR    H", terminator: "")
        break
    case 0x25:
        print("DCR    H", terminator: "")
        break
    case 0x26:
        print(String(format: "MVI    H,#$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0x27:
        print("DAA", terminator: "")
        break
    case 0x28:
        print("NOP", terminator: "")
        break
    case 0x29:
        print("DAD    H", terminator: "")
        break
    case 0x2a:
        print(String(format: "LHLD    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0x2b:
        print("DCX    H", terminator: "")
        break
    case 0x2c:
        print("INR    L", terminator: "")
        break
    case 0x2d:
        print("DCR    L", terminator: "")
        break
    case 0x2e:
        print(String(format: "MVI    L,#$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0x2f:
        print("CMA", terminator: "")
        break
        
        
    case 0x30:
        print("SIM", terminator: "")
        break
    case 0x31:
        print(String(format: "LXI    SP,#$%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0x32:
        print(String(format: "STA    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0x33:
        print("INX    SP", terminator: "")
        break
    case 0x34:
        print("INR    M", terminator: "")
        break
    case 0x35:
        print("DCR    M", terminator: "")
        break
    case 0x36:
        print(String(format: "MVI    M,#$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0x37:
        print("STC", terminator: "")
        break
    case 0x38:
        print("NOP", terminator: "")
        break
    case 0x39:
        print("DAD    SP", terminator: "")
        break
    case 0x3a:
        print(String(format: "LDA    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0x3b:
        print("DCX    SP", terminator: "")
        break
    case 0x3c:
        print("INR    A", terminator: "")
        break
    case 0x3d:
        print("DCR    A", terminator: "")
        break
    case 0x3e:
        print(String(format: "MVI    A,#$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0x3f:
        print("CMC", terminator: "")
        break
        
    // 0x40 - 0x7f: MOV and friends
    
    case 0x76:
        print("HLT", terminator: "")
        break
        
    // 0x80 - 0xbf: ALU
        
    
    // 0xc0 - 0xff: Other important things
        
    case 0xc0:
        print("RNZ", terminator: "")
        break
    case 0xc1:
        print("POP    B", terminator: "")
        break
    case 0xc2:
        print(String(format: "JNZ    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xc3:
        print(String(format: "JMP    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xc4:
        print(String(format: "CNZ    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xc5:
        print("PUSH    B", terminator: "")
        break
    case 0xc6:
        print(String(format: "ADI    #$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0xc7:
        print("RST    0", terminator: "")
        break
    case 0xc8:
        print("RZ", terminator: "")
        break
    case 0xc9:
        print("RET", terminator: "")
        break
    case 0xca:
        print(String(format: "JZ    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xcb:
        print("NOP", terminator: "")
        break
    case 0xcc:
        print(String(format: "CZ    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xcd:
        print(String(format: "CALL    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xce:
        print(String(format: "ACI    #$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0xcf:
        print("RST    1", terminator: "")
        break
        
    
    case 0xd0:
        print("RNC", terminator: "")
        break
    case 0xd1:
        print("POP    D", terminator: "")
        break
    case 0xd2:
        print(String(format: "JNC    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xd3:
        print(String(format: "OUT    #$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0xd4:
        print(String(format: "CNC    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xd5:
        print("PUSH    D", terminator: "")
        break
    case 0xd6:
        print(String(format: "SUI    #$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0xd7:
        print("RST    2", terminator: "")
        break
    case 0xd8:
        print("RC", terminator: "")
        break
    case 0xd9:
        print("NOP", terminator: "")
        break
    case 0xda:
        print(String(format: "JC    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xdb:
        print(String(format: "IN    #$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0xdc:
        print(String(format: "CC    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xdd:
        print("NOP", terminator: "")
        opbytes = 3
        break
    case 0xde:
        print(String(format: "SBI    #$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0xdf:
        print("RST    3", terminator: "")
        break
        
    case 0xe0:
        print("RPO", terminator: "")
        break
    case 0xe1:
        print("POP    H", terminator: "")
        break
    case 0xe2:
        print(String(format: "JPO    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xe3:
        print("XTHL", terminator: "")
        break
    case 0xe4:
        print(String(format: "CPO    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xe5:
        print("PUSH    H", terminator: "")
        break
    case 0xe6:
        print(String(format: "ANI    #$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0xe7:
        print("RST    4", terminator: "")
        break
    case 0xe8:
        print("RPE", terminator: "")
        break
    case 0xe9:
        print("PCHL", terminator: "")
        break
    case 0xea:
        print(String(format: "JPE    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xeb:
        print("XCHG", terminator: "")
        break
    case 0xec:
        print(String(format: "CPE    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xed:
        print("NOP", terminator: "")
        opbytes = 3
        break
    case 0xee:
        print(String(format: "XRI    #$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0xef:
        print("RST    5", terminator: "")
        break
        
    case 0xf0:
        print("RP", terminator: "")
        break
    case 0xf1:
        print("POP    PSW", terminator: "")
        break
    case 0xf2:
        print(String(format: "JP    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xf3:
        print("DI", terminator: "")
        break
    case 0xf4:
        print(String(format: "CP    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xf5:
        print("PUSH    PSW", terminator: "")
        break
    case 0xf6:
        print(String(format: "ORI    #$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0xf7:
        print("RST    6", terminator: "")
        break
    case 0xf8:
        print("RM", terminator: "")
        break
    case 0xf9:
        print("SPHL", terminator: "")
        break
    case 0xfa:
        print(String(format: "JM    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xfb:
        print("EI", terminator: "")
        opbytes = 2
        break
    case 0xfc:
        print(String(format: "CM    $%02x%02x", code[2], code[1]), terminator: "")
        opbytes = 3
        break
    case 0xfd:
        print("NOP", terminator: "")
        opbytes = 3
        break
    case 0xfe:
        print(String(format: "CPI    #$%02x", code[1]), terminator: "")
        opbytes = 2
        break
    case 0xff:
        print("RST    7", terminator: "")
        break
    
        
    default:
        print(String(format: "UNKNOWN    0x%02x", instr), terminator: "")
    }
    
    print("\n", terminator: "")
    return opbytes
}
