//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Whealy, Chris on 08/06/2016.
//  Copyright © 2016 Whealy, Chris. All rights reserved.
//

import Foundation

var memory      = Memory.registers
var k_registers = Memory.k_registers

private var accumulator = 0.0

private var kInRegisterNeedsIndex  = false
private var kOutRegisterNeedsIndex = false

private var savedProgram: Node? = nil

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Add or remove the current accumulator value to/from memory or K Registers
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
func handleMemory(opCode: String) {
  debugPrint("brain.handleMemory() : opCode = \(opCode)")

  if isOpCodeAVariable(opCode) {
    memory[opCode] = accumulator
  }
  else {
    switch opCode {
      case "MR"     : accumulator = memory["m"]!
      case "inv_MR" : memory["m"] = accumulator
      case "M+"     : memory["m"] = memory["m"]! + accumulator
      case "inv_M+" : memory["m"] = memory["m"]! - accumulator

      case "K in"   : kInRegisterNeedsIndex  = true
                      kOutRegisterNeedsIndex = false
      case "K out"  : kInRegisterNeedsIndex  = false
                      kOutRegisterNeedsIndex = true

      default       : break
    }
  }

  debugPrint("brain.handleMemory() : memory = \(memory)")
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Retrieve memory value
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
func retrieveMemoryValue(opCode: String) -> Double? {
  let thisOpCode = opCode == "MR" ? "m" : opCode

  return isOpCodeAVariable(thisOpCode) ? memory[thisOpCode]!
                                       : nil
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Retrieve memory value via a function
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
func retrieveMemoryValueAsFunction(opCode: String) -> () -> Double? {
  let thisOpCode = opCode == "MR" ? "m" : opCode

  return isOpCodeAVariable(thisOpCode) ? { () in memory[thisOpCode]! }
                                       : { () in nil }
}


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Here's the brain
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
class CalculatorBrain {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // The current calculation is held as a tree of Nodes
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  private var tree         : Node?
  private var pendingSymbol: Node?

  private var needMoreOperands = false

  private var prevOp = ""

  // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  // Public API
  // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  func setOperand(op: Double) {
    debugPrint("brain.setOperand() : received operand \(op)")

    // Are we waiting for the user to enter a K register index number?
    if KIndexNeeded {
      // Yup, so treat the operand as the K register index number
      let idx = Int(op) - 1

      switch idx {
        case 0..<k_registers.count:
          if kInRegisterNeedsIndex {
            k_registers[idx] = accumulator
            kInRegisterNeedsIndex = false
          }
          else {
            accumulator = k_registers[idx]
            kOutRegisterNeedsIndex = false
          }

          debugPrint(k_registers)

        default: break
      }
    }
    // Nope, so the number just entered becomes the new accumulator
    else {
      accumulator = op
    }

    if !needMoreOperands { tree = nil }

    debugPrint("brain.setOperand() : accumulator = \(accumulator)")
  }

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Clear storage
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  func clearKRegisters() { k_registers = k_registers.map() { _ in 0.0 } }

  func resetBrain() {
    debugPrint("brain.resetBrain()")
    tree            = nil
    pendingSymbol   = nil
    accumulator     = 0.0
  }



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Handle memory and program operations
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  func setMemory(opCode: String) { handleMemory(opCode) }

  func saveProgram()    {
    if tree != nil {
      savedProgram = tree
    }

    debugPrint("brain.saveProgram() : savedProgram = \(savedProgram?.toString())")
  }

  func clearProgram()   {
    debugPrint("brain.clearProgram()")
    savedProgram = nil
  }

  func restoreProgram() {
    if savedProgram != nil {
      accumulator = savedProgram!.evaluate()!
      tree = savedProgram
    }

    debugPrint("brain.restoreProgram() : Tree = \(tree?.toString())")
  }

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Build the computation tree based on the current operation
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  func buildComputationTree(keyValue: String, inv: Bool, degMode: Bool) {
    // Combine the name of the key pressed together with the states of the inverse and degree
    // mode indicators to derive the exact op code to be performed
    let opCode = (inv ? "inv_" : "") +
                 keyValue +
                 (["sin","cos","tan"].indexOf(keyValue) != nil ? (degMode ? "Deg" : "Rad") : "")

    debugPrint("brain.buildComputationTree() : Received opCode \(opCode)")

    if let operation = operations[opCode] {
      switch operation {
        // ---------------------------------------------------------------------------------------
        case .MemoryFunction :
          debugPrint("brain.buildComputationTree() : Processing memory function")

          // Retrieving a value from memory or referencing a variable must not insert any specific
          // value into the current node as these values can change between program executions
          if opCode == "MR" || isOpCodeAVariable(opCode) {
            let tempNode = Node(opCode: opCode)

            if implicitMultiplication {
              debugPrint("brain.buildComputationTree() : Performing implicit multiplication")
              pendingSymbol = Node(opCode: "×").addLeftChild(Node(value: accumulator)).addRightChild(tempNode)
              pendingSymbol?.opIsImplicit = true
            }
            else {
              debugPrint("brain.buildComputationTree() : Performing explicit operation")
              pendingSymbol = tempNode
            }

            if !needMoreOperands { tree = nil }

            needMoreOperands       = true
            implicitMultiplication = false
          }
          else {
            handleMemory(opCode)
          }

          debugPrint("pendingSymbol = \(pendingSymbol?.toString())")


        // ---------------------------------------------------------------------------------------
        case .Constant(let val) :
          debugPrint("brain.buildComputationTree() : Processing constant")
          accumulator = val
          pendingSymbol = Node(opCode: keyValue, value: val)

          // If the user presses a numeric symbol after a completed computation has been
          // performed, then we're starting a new computation, so zap the tree
          if !needMoreOperands { tree = nil }
          needMoreOperands = true

        // ---------------------------------------------------------------------------------------
        case .Random(let fn) :
          debugPrint("brain.buildComputationTree() : Processing random number")
          accumulator = fn()
          pendingSymbol = Node(opCode: keyValue, value: accumulator)

          // If the user asks for a random number after a completed computation has been
          // performed, then we're starting a new computation, so zap the tree
          if !needMoreOperands { tree = nil }
          needMoreOperands = true

        // ---------------------------------------------------------------------------------------
        case .Equals :
          debugPrint("brain.buildComputationTree() : Processing equals")

          let currentValue = pendingSymbol == nil
                             ? Node(value: accumulator)
                             : pendingSymbol!

          debugPrint("Current value = \(currentValue.toString())")

          // Is the tree empty?
          if tree != nil {
            debugPrint("Evaluating tree")

            // Nope, so are more operands needed?
            if needMoreOperands {
              // Yup, so the current accumulator becomes the right node of the tree
              tree!.addRightChild(currentValue)
            }

            // Calculate!
            accumulator = tree!.evaluate()!
          }
          else {
            debugPrint("Evaluating pendingSymbol")
            accumulator = currentValue.evaluate()!
            tree = pendingSymbol
          }

          pendingSymbol    = nil
          needMoreOperands = false

        // ---------------------------------------------------------------------------------------
        case .UnaryOperation :
          debugPrint("brain.buildComputationTree() : Processing unary function")
          debugPrint("brain.buildComputationTree() : Tree before operation = \(tree?.toString())")

          let tempNode = Node(opCode: opCode).addLeftChild(pendingSymbol == nil
                                                           ? Node(value: accumulator)
                                                           : pendingSymbol!)

          debugPrint("brain.buildComputationTree() : tempNode = \(tempNode.toString())")

          // Is the tree empty?
          if tree == nil {
            // Yup, so the current computation becomes the new tree
            tree = tempNode
          }
          else {
            // Are we part way through a binary operation?
            if needMoreOperands {
              // Yup, so the current unary operation becomes the new right child of the current node
              tree!.addRightChild(tempNode)
            }
            else {
              // Nope, so the unary operation needs to be applied to the entire computation tree
              tree = Node(opCode: opCode).addLeftChild(tree!)
            }
          }

          debugPrint("brain.buildComputationTree() : Tree after operation = \(tree?.toString())")
          debugPrint("brain.buildComputationTree() : New accumulator value = \(tempNode.evaluate()!)")

          accumulator      = tempNode.evaluate()!
          pendingSymbol    = nil
          needMoreOperands = false

        // ---------------------------------------------------------------------------------------
        case .BinaryOperation :
          debugPrint("brain.buildComputationTree() : Processing binary function")
          debugPrint("brain.buildComputationTree() : Tree before operation = \(tree?.toString())")

          let currentValue = pendingSymbol == nil
                             ? Node(value: accumulator)
                             : pendingSymbol!

          // Is the tree is empty?
          if tree == nil {
            // Yup, so we're starting a new computation
            tree = Node(opCode: opCode).addLeftChild(currentValue)
          }
          else {
          // Nope, so check if we're halfway through a binary operation
            if needMoreOperands {
              // Yup, so the current accumulator value becomes the right child of the current tree node
              // The current tree node then becomes the left child of a new parent node with the current
              // opCode as the new node's value
              tree = Node(opCode: opCode).addLeftChild(tree!.addRightChild(currentValue))
            }
            else {
              // A new binary operation is being started that uses the current result as its first argument
              // The current tree becomes the left child of a new parent tree node
              tree = Node(opCode: opCode).addLeftChild(tree!)
            }
          }

          debugPrint("brain.buildComputationTree() : Tree after operation = \(tree?.toString())")
          pendingSymbol    = nil
          needMoreOperands = true
      }
    }

    prevOp = opCode
  }

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Calculated properties
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  var resultAsString:  String {
    get { return tree == nil
                 ? pendingSymbol == nil
                   ? String(accumulator)
                   : pendingSymbol!.toString()
                 : tree!.toString()
    }
  }

  var kRegisterFlags  : Array<Bool> { get { return k_registers.map() {$0 != 0.0 } } }
  var result          : Double      { get { return accumulator } }
  var memHasContents  : Bool        { get { return memory["m"]! != 0.0 } }
  var KIndexNeeded    : Bool        { get { return kInRegisterNeedsIndex || kOutRegisterNeedsIndex } }
  var isPartialResult : Bool        { get { return needMoreOperands } }
  var hasSavedProgram : Bool        { get { return savedProgram != nil } }
  var getSavedProgram : Node?       { get { return savedProgram } }

  var implicitMultiplication : Bool = false
}










