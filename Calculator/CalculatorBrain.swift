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
  typealias UnaryFunction  = (Double) -> Double
  typealias BinaryFunction = (Double, Double) -> Double

  private func unaryOperation(unaryFn: UnaryFunction) -> (Double) -> Double {
    return {(val: Double) -> Double in
      return unaryFn(val)
    }
  }

  private func binaryOperation(binaryFn: BinaryFunction) -> (Double) -> (Double) -> Double {
    return {(val1: Double) -> (Double) -> Double in
      return {(val2: Double) -> Double in
        binaryFn(val1,val2)
      }
    }
  }


  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Struct for holding a pending binary operation
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  private struct pendingBinaryOperation {
    var binFn: (Double, Double) -> Double
    var op1:   Double
  }

  private var pending: pendingBinaryOperation?
  private var accumulator = 0.0
  private var memory      = 0.0

  private var _prevOpIsUnary = false
  private var _thisOpIsUnary = false

  // Operation types
  private enum Operation {
    case MemoryFunction
    case Random
    case Constant(Double)
    case UnaryOperation((Double) -> Double)
    case BinaryOperation((Double, Double) -> Double)
    case Equals
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Tuple for remebering each step of the calculator's program
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  typealias ProgramStep = (operand   : Double,
                           operatr   : String,
                           inverse   : Bool,
                           degreeMode: Bool,
                           isUnary   : Bool)

  private var internalProgram = [ProgramStep]()

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Functions this calculator can perform
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  private let operations: Dictionary<String, Operation> = [
    // Operations and their inverses.  Some operations have no inverse
    // OPerations for resetting or completing a calculation
    "="          : Operation.Equals,
    "inv_="      : Operation.Equals,

    // Memory functions
    "M+"         : Operation.MemoryFunction,
    "inv_M+"     : Operation.MemoryFunction,
    "MR"         : Operation.MemoryFunction,
    "inv_MR"     : Operation.MemoryFunction,

    // Mathematical constants
    "π"          : Operation.Constant(M_PI),
    "inv_π"      : Operation.Constant(M_PI),
    "e"          : Operation.Constant(M_E),
    "inv_e"      : Operation.Constant(M_E),
    "Rnd"        : Operation.Random,
    "inv_Rnd"    : Operation.Random,

    // Basic operations such as square root, exponentiation, logs and factorial
    "±"          : Operation.UnaryOperation({ -$0 }),
    "inv_±"      : Operation.UnaryOperation({ -$0 }),
    "√"          : Operation.UnaryOperation(sqrt),
    "inv_√"      : Operation.UnaryOperation({ $0 * $0 }),
    "1/x"        : Operation.UnaryOperation({ 1 / $0 }),
    "inv_1/x"    : Operation.UnaryOperation(factorial),
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

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Complete a pending binary operation
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  private func executePendingBinaryOperation() {
    if pending != nil {
      accumulator = pending!.binFn(pending!.op1, accumulator)
      pending = nil
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Add or remove the current accumulator value to/from memory
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  private func handleMemory(opCode: String) {
    switch opCode {
      case "MR"     : accumulator = memory
      case "inv_MR" : memory = accumulator
      case "M+"     : memory += accumulator
      case "inv_M+" : memory -= accumulator

      default : break
    }
  }

  // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  // Public API
  // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  var program: [ProgramStep] {
    get { return internalProgram }
    set {
      resetBrain()

      for pgmStep in newValue {
        if pgmStep.operatr != "" {
          performOperation(pgmStep.operatr, inv: pgmStep.inverse, degMode: pgmStep.degreeMode)
        }
        else {
          setOperand(pgmStep.operand)
        }
      }
    }
  }

  func setOperand(op: Double) {
    print("Brain received operand \(op)")
    accumulator = op
    internalProgram.append((op, "", false, true, false))
  }

  func clearLastOp() {
    if pending != nil {
      accumulator = 0.0
    }

    internalProgram.removeLast()
  }

  func resetBrain() {
    pending         = nil
    _prevOpIsUnary  = false
    _thisOpIsUnary  = false
    accumulator     = 0.0
    internalProgram = []
  }

  func performOperation(keyValue: String, inv: Bool, degMode: Bool) {
    // Combine the name of the key pressed together with the states of the inverse and degree
    // mode indicators to derive the exact op code to be performed
    let opCode = (inv ? "inv_" : "") +
                 keyValue +
                 (["sin","cos","tan"].indexOf(keyValue) != nil ? (degMode ? "Deg" : "Rad") : "")

    print("Invoking opcode = \(opCode)")

    if let operation = operations[opCode] {
      switch operation {
        case .MemoryFunction          : handleMemory(opCode)
        case .Constant(let val)       : accumulator = val
        case .Random                  : accumulator = drand48()

        case .Equals                  :
          executePendingBinaryOperation()
          _prevOpIsUnary = _thisOpIsUnary
          _thisOpIsUnary = false

        case .UnaryOperation(let fn)  :
          accumulator = fn(accumulator)
          _prevOpIsUnary = _thisOpIsUnary
          _thisOpIsUnary = true

        case .BinaryOperation(let fn) :
          executePendingBinaryOperation()
          pending = pendingBinaryOperation(binFn: fn, op1: accumulator)
          _prevOpIsUnary = _thisOpIsUnary
          _thisOpIsUnary = false
      }
    }

    internalProgram.append((0.0, keyValue, inv, degMode, _prevOpIsUnary))
//    print(internalProgram)
  }

  var result:          Double { get { return accumulator } }
  var memHasContents:  Bool   { get { return memory != 0.0 } }
  var isPartialResult: Bool   { get { return pending != nil } }
  var prevOpIsUnary:   Bool   { get { return _prevOpIsUnary } }
  var thisOpIsUnary:   Bool   { get { return _thisOpIsUnary } }
}










