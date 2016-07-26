//
//  Operations.swift
//  Calculator2
//
//  Created by Whealy, Chris on 21/07/2016.
//  Copyright © 2016 Whealy, Chris. All rights reserved.
//

import Foundation


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Functions for various mathematical operations
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
func factorial(n: Double) -> Double {
  let intVal = Int(n)
  return intVal < 2 ? 1 : Double([Int](2...intVal).reduce(1) { $0 &* $1 })
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Operation types
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
enum Operation {
  case MemoryFunction
  case Random(() -> Double)
  case Constant(Double)
  case UnaryOperation((Double) -> Double)
  case BinaryOperation((Double, Double) -> Double)
  case Equals
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Operations this calculator can perform
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
let operations: [String:Operation] = {
  var tempDict = [
    // Operations and their inverses.  Some operations have no inverse
    // OPerations for resetting or completing a calculation
    "="          : Operation.Equals,
    "inv_="      : Operation.Equals,

    // Memory functions
    "K in"       : Operation.MemoryFunction,
    "inv_K in"   : Operation.MemoryFunction,
    "K out"      : Operation.MemoryFunction,
    "inv_K out"  : Operation.MemoryFunction,
    "M+"         : Operation.MemoryFunction,
    "inv_M+"     : Operation.MemoryFunction,
    "MR"         : Operation.MemoryFunction,
    "inv_MR"     : Operation.MemoryFunction,

    // Numerical symbols
    "π"          : Operation.Constant(M_PI),
    "inv_π"      : Operation.Constant(M_PI),
    "e"          : Operation.Constant(M_E),
    "inv_e"      : Operation.Constant(M_E),
    "Rnd"        : Operation.Random({ drand48() }),
    "inv_Rnd"    : Operation.Random({ drand48() }),

    // Basic operations such as square root, exponentiation, logs and factorial
    "±"          : Operation.UnaryOperation({ -$0 }),
    "inv_±"      : Operation.UnaryOperation({ $0 * $0 }),
    "√"          : Operation.UnaryOperation(sqrt),
    "inv_√"      : Operation.UnaryOperation(sqrt),
    "1/x"        : Operation.UnaryOperation({ 1 / $0 }),
    "inv_1/x"    : Operation.UnaryOperation({ 1 / $0 }),
    "!"          : Operation.UnaryOperation(factorial),
    "inv_!"      : Operation.UnaryOperation(factorial),
    "log"        : Operation.UnaryOperation(log10),
    "inv_log"    : Operation.UnaryOperation(__exp10),
    "ln"         : Operation.UnaryOperation(log),
    "inv_ln"     : Operation.UnaryOperation(exp),

    // Trig functions in degrees
    "sinDeg"     : Operation.UnaryOperation({ sin($0 * M_PI / 180) }),
    "cosDeg"     : Operation.UnaryOperation({ cos($0 * M_PI / 180) }),
    "tanDeg"     : Operation.UnaryOperation({ tan($0 * M_PI / 180) }),
    "inv_sinDeg" : Operation.UnaryOperation({ asin($0) * 180 / M_PI }),
    "inv_cosDeg" : Operation.UnaryOperation({ acos($0) * 180 / M_PI }),
    "inv_tanDeg" : Operation.UnaryOperation({ atan($0) * 180 / M_PI }),

    // Trig functions in radians
    "sinRad"     : Operation.UnaryOperation(sin),
    "cosRad"     : Operation.UnaryOperation(cos),
    "tanRad"     : Operation.UnaryOperation(tan),
    "inv_sinRad" : Operation.UnaryOperation(asin),
    "inv_cosRad" : Operation.UnaryOperation(acos),
    "inv_tanRad" : Operation.UnaryOperation(atan),

    // Arithmetic operations
    "+"          : Operation.BinaryOperation({ $0 + $1 }),
    "inv_+"      : Operation.BinaryOperation({ $0 + $1 }),
    "−"          : Operation.BinaryOperation({ $0 - $1 }),
    "inv_−"      : Operation.BinaryOperation({ $0 - $1 }),
    "×"          : Operation.BinaryOperation({ $0 * $1 }),
    "inv_×"      : Operation.BinaryOperation(pow),
    "÷"          : Operation.BinaryOperation({ $0 / $1 }),
    "inv_÷"      : Operation.BinaryOperation({ pow($0,(1/$1)) })
  ]

  for i in 97...122 {
    tempDict.updateValue(Operation.MemoryFunction, forKey: String(UnicodeScalar(i)))
  }

  return tempDict
}()

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Display strings used for inverse op codes
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
let inverseOpCodes: Dictionary<String, String> = [
  "inv_log"    : "10^",
  "inv_ln"     : "e^",
  "inv_sinDeg" : "asin",
  "inv_sinRad" : "asin",
  "inv_cosDeg" : "acos",
  "inv_cosRad" : "acos",
  "inv_tanDeg" : "atan",
  "inv_tanRad" : "atan",
  "inv_±"      : "^2",
  "inv_×"      : "^",
  "inv_÷"      : "^1/"]


