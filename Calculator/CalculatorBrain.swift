//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Whealy, Chris on 08/06/2016.
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

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Here's the brain
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
class CalculatorBrain {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Struct for storing the operator and operand of a pending operation
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  private struct pendingBinOpInfo {
    var binFn: (Double, Double) -> Double
    var op1:   Double
  }

  private var pending: pendingBinOpInfo?

  private var accumulator = 0.0

  // Operation types
  private enum Operation {
    case Reset
    case ClearLastOperand
    case Constant(Double)
    case UnaryOperation((Double) -> Double)
    case BinaryOperation((Double, Double) -> Double)
    case Equals
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Functions this calculator can perform
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  private var operations: Dictionary<String, Operation> = [
    // Operations and their inverses.  Some operations have no inverse
    // OPerations for resetting or completing a calculation
    "AC"         : Operation.Reset,
    "inv_AC"     : Operation.Reset,
    "C"          : Operation.ClearLastOperand,
    "inv_C"      : Operation.ClearLastOperand,
    "="          : Operation.Equals,
    "inv_="      : Operation.Equals,

    // Mathematical constants
    "π"          : Operation.Constant(M_PI),
    "inv_π"      : Operation.Constant(M_PI),
    "e"          : Operation.Constant(M_E),
    "inv_e"      : Operation.Constant(M_E),

    // Basic operations such as square root, exponentiation, logs and factorial
    "±"          : Operation.UnaryOperation({ -$0 }),
    "inv_±"      : Operation.UnaryOperation({ -$0 }),
    "√"          : Operation.UnaryOperation(sqrt),
    "inv_√"      : Operation.UnaryOperation(sqrt),
    "x!"         : Operation.UnaryOperation(factorial),
    "inv_x!"     : Operation.UnaryOperation(factorial),
    "x^2"        : Operation.UnaryOperation({ $0 * $0 }),
    "inv_x^2"    : Operation.UnaryOperation({ $0 * $0 }),
    "1/x"        : Operation.UnaryOperation({ 1 / $0 }),
    "inv_1/x"    : Operation.UnaryOperation({ 1 / $0 }),
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

  private func executePendingBinaryOperation() {
    if pending != nil {
      accumulator = pending!.binFn(pending!.op1, accumulator)
      pending = nil
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Public API
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  func setOperand(operand: Double) { accumulator = operand }

  func performOperation(keyValue: String, inv: Bool, degMode: Bool) {
    let opCode = (inv ? "inv_" : "") + keyValue +
                 (["sin","cos","tan"].indexOf(keyValue) != nil ? (degMode ? "Deg" : "Rad") : "")

    print("Looking up opcode = \(opCode)")

    if let operation = operations[opCode] {
      switch operation {
        case .Reset:
          accumulator = 0.0; pending = nil

        case .ClearLastOperand:
          accumulator = 0.0

        case .Constant(let val):
          accumulator = val

        case .UnaryOperation(let fn):
          accumulator = fn(accumulator)

        case .BinaryOperation(let fn):
          executePendingBinaryOperation()
          pending = pendingBinOpInfo(binFn: fn, op1: accumulator)

        case .Equals:
          executePendingBinaryOperation()
      }
    }

  }

  var result: Double { get { return accumulator } }
}


