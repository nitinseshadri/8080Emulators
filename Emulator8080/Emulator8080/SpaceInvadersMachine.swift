//
//  SpaceInvadersMachine.swift
//  Emulator8080
//
//  Created by Nitin Seshadri on 7/17/22.
//

import Foundation

// A Machine subclass that supports Space Invaders.
class SpaceInvadersMachine: Machine {
    
    private var lastInterruptTime: TimeInterval = Date.timeIntervalSinceReferenceDate
    
    override func execute() {
        super.execute()
        
        if ((Date.timeIntervalSinceReferenceDate - lastInterruptTime) > (1/60)) {
            _ = cpu.interrupt(2)
            
            lastInterruptTime = Date.timeIntervalSinceReferenceDate
        }
    }
    
}
