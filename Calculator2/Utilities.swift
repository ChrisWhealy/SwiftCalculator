//
//  Utilities.swift
//  Calculator2
//
//  Created by Whealy, Chris on 21/07/2016.
//  Copyright © 2016 Whealy, Chris. All rights reserved.
//

import Foundation

func isOpCodeAVariable(opCode: String) -> Bool {
  // Return true if the opCode is a single character, alphabetic string
  return opCode.characters.count != 1
         ? false
         : opCode.unicodeScalars.first?.value >= 97 &&
           opCode.unicodeScalars.first?.value <= 122
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Identify numeric symbols such as π, e or Rnd.
// This is where the numeric symbol must be displayed in the computation string instead of
// the symbol's value
func isNumericSymbol(s: String) -> Bool {
  return ["π","e","Rnd","MR"].indexOf(s) > -1
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Identify postfix operators
func isPostFixOperator(op: String) -> Bool {
  return ["!","^2"].indexOf(op) > -1
}

// Handle potential overflow when converting doubles that are > Int.max to string
func doubleToIntWithoutOverflow(dbl: Double) -> String {
  return dbl <= Double(Int.max) && dbl % 1 == 0 ? String(Int(dbl)) : String(dbl)
}


