//
//  Memory.swift
//  Calculator2
//
//  Created by Whealy, Chris on 08/07/2016.
//  Copyright © 2016 Whealy, Chris. All rights reserved.
//

import Foundation

class Memory {
  static var registers: [String:Double] = {
    var mem = [String:Double]()

    // Initialise all memory registers
    for i in 97...122 { mem[String(UnicodeScalar(i))] = 0.0 }

    return mem
  }()

  static var k_registers: Array<Double> = [0.0,0.0,0.0,0.0,0.0,0.0]
}









