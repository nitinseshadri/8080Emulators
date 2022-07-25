//
//  main.swift
//  Disassemble8080
//
//  Created by Nitin Seshadri on 7/12/22.
//

import Foundation

let argc = ProcessInfo.processInfo.arguments.count

let argv = ProcessInfo.processInfo.arguments

print("8080 Disassembler\n")

if argc < 2 {
    print("Missing file to disassemble")
    exit(-1)
}

let binURL = URL(fileURLWithPath: argv[1])

guard let binData = try? Data(contentsOf: binURL) else {
    print("Could not read file at \(binURL.absoluteString)")
    exit(-1)
}

let bytes = binData.bytes

let byteCount = binData.bytes.count

var pc = 0

while (pc < byteCount) {
    pc += disassemble8080Opcode(bytes: bytes, pc: pc)
}

print("\nEnd of file")

exit(0)

