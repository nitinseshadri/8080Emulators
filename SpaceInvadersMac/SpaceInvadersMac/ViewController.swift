//
//  ViewController.swift
//  SpaceInvadersMac
//
//  Created by Nitin Seshadri on 7/17/22.
//

import Cocoa

class ViewController: NSViewController {
    
    weak var appDelegate: AppDelegate? {
        let delegate = NSApplication.shared.delegate as? AppDelegate
        return delegate
    }
    
    weak var machine: SpaceInvadersMachine? {
        return appDelegate?.machine
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        startButton?.wantsLayer = true
        // Interestingly, the max z-index is the greatest finite magnitude of Float, not that of CGFloat (which is higher)
        startButton?.layer?.zPosition = CGFloat(Float.greatestFiniteMagnitude)
        startButton?.appearance = NSAppearance(named: .darkAqua)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: Start, stop, and step buttons
    
    @IBOutlet weak var startButton: NSButton?
    
    @IBOutlet weak var stepButton: NSButton?
    
    @IBOutlet weak var stopButton: NSButton?
    
    @IBOutlet weak var stepCountField: NSTextField?
    
    // Start or resume emulation.
    @IBAction private func start(_ sender: Any) {
        appDelegate?.startEmulation()
        
        startButton?.isHidden = true
        stepButton?.isEnabled = false
        stopButton?.isEnabled = true
    }
    
    // Execute n instructions. Useful for debugging.
    @IBAction private func step(_ sender: Any) {
        let stepCount = stepCountField?.integerValue ?? 1
        
        startButton?.isHidden = true
        stepButton?.isEnabled = false
        stopButton?.isEnabled = false
        
        DispatchQueue.global(qos: .userInteractive).async { [unowned self] in
            for _ in 1...stepCount {
                machine?.execute()
                machine?.cpu.printState(disassemble: false)
            }
            
            DispatchQueue.main.async { [unowned self] in
                startButton?.isHidden = false
                stepButton?.isEnabled = true
                stopButton?.isEnabled = false
            }
        }
    }
    
    // Stop emulation.
    @IBAction private func stop(_ sender: Any) {
        appDelegate?.stopEmulation()
        
        startButton?.isHidden = false
        stepButton?.isEnabled = true
        stopButton?.isEnabled = false
    }
    
}

