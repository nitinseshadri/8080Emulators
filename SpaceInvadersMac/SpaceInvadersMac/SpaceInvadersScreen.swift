//
//  SpaceInvadersScreen.swift
//  Space Invaders
//
//  Created by Nitin Seshadri on 7/17/22.
//

import Cocoa

class SpaceInvadersScreen: NSView {
    
    private var renderTimer: Timer? = nil
    
    weak var appDelegate: AppDelegate? {
        let delegate = NSApplication.shared.delegate as? AppDelegate
        return delegate
    }
    
    weak var machine: SpaceInvadersMachine? {
        return appDelegate?.machine
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Enable layer backing and set background.
        self.wantsLayer = true
        layer?.backgroundColor = .black
        
        // Rotate the view to simplify drawing the framebuffer.
        // Note: isFlipped is true so we have an iOS-like coordinate system.
        self.rotate(byDegrees: 90.0)
        
        // Start drawing the framebuffer.
        renderTimer = Timer(timeInterval: (1/60), repeats: true) { [unowned self] timer in
            drawEmulatorFramebuffer()
        }
        
        if let renderTimer = renderTimer {
            RunLoop.main.add(renderTimer, forMode: .common)
        }
    }
    
    override var isFlipped: Bool {
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
    }
    
    private func drawEmulatorFramebuffer() {
        if (appDelegate?.isEmulatorRunning == true) {
            guard let machine = machine else {
                print("Machine is nil")
                return
            }
            
            guard let imageRepresentation = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 256, pixelsHigh: 224, bitsPerSample: 1, samplesPerPixel: 1, hasAlpha: false, isPlanar: false, colorSpaceName: .calibratedWhite, bytesPerRow: 32, bitsPerPixel: 1) else {
                print("Failed to create bitmap image representation")
                return
            }
            
            for offset in 0..<32*224 {
                imageRepresentation.bitmapData?[offset] = machine.cpu.memory[machine.framebufferEndLocation - offset]
            }
            
            let image = NSImage(size: .init(width: 256, height: 224))
            image.addRepresentation(imageRepresentation)
            
            layer?.contents = image
            
            #if DEBUG
            try? imageRepresentation.tiffRepresentation?.write(to: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("framebuffer.tiff"))
            #endif
        }
    }
    
}
