//
//  main.swift
//  Emulator8080
//
//  Created by Nitin Seshadri on 7/12/22.
//

import Foundation

let argc = ProcessInfo.processInfo.arguments.count

let argv = ProcessInfo.processInfo.arguments

print("8080 Emulator\n")

if argc < 2 {
    print("Missing file to emulate")
    exit(-1)
}

let binURL = URL(fileURLWithPath: argv[1])

guard let binData = try? Data(contentsOf: binURL) else {
    print("Could not read file at \(binURL.absoluteString)")
    exit(-1)
}

print("Loaded file \(binURL.lastPathComponent)")

let bytes = binData.bytes

let machine = SpaceInvadersMachine(memorySize: 64*1024) // 64K bytes address space

_ = machine.mapIntoMemory(bytes: bytes, startingAt: 0x0000)

//_ = machine.mapIntoMemory(bytes: bytes, startingAt: 0x0100)
//machine.cpu.programCounter = 0x0100

while true {
    machine.execute()
}

print("\nEmulation ended")

exit(0)

