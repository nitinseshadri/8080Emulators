//
//  AppDelegate.swift
//  SpaceInvadersMac
//
//  Created by Nitin Seshadri on 7/17/22.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    public let machine = SpaceInvadersMachine(memorySize: 64*1024) // 64K bytes address space
    
    public private(set) var isEmulatorRunning: Bool = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        loadROM()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
        stopEmulation()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func loadROM() {
        let binURL = Bundle.main.url(forResource: "invaders", withExtension: "rom")
        
        guard let binURL = binURL else {
            print("Could not read ROM file")
            return
        }

        guard let binData = try? Data(contentsOf: binURL) else {
            print("Could not get data from ROM file at \(binURL.absoluteString)")
            return
        }

        let bytes = binData.bytes

        _ = machine.mapIntoMemory(bytes: bytes, startingAt: 0x0000)
        
        print("Mapped \(binURL.lastPathComponent) into emulator memory")
    }
    
    public func startEmulation() {
        isEmulatorRunning = true
        DispatchQueue.global(qos: .userInteractive).async { [unowned self] in
            while (isEmulatorRunning) {
                machine.execute()
            }
        }
        print("Started emulation")
    }
    
    public func stopEmulation() {
        isEmulatorRunning = false
        print("Stopped emulation")
    }
    
    /*
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if (flag) { // There are visible windows.
            if (window.isMiniaturized) {
                window.deminiaturize(nil)
            }
            return false
        } else { // There are no visible windows.
            window.makeKeyAndOrderFront(nil)
            return true
        }
    }
     */

}

