//
//  Data+Extensions.swift
//  VirtualCard
//
//  Created by Nitin Seshadri on 9/4/21.
//

import Foundation

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}
