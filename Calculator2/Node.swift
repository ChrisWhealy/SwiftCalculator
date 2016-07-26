//
//  CalculationTreeNode.swift
//  Calculator2
//
//  Created by Whealy, Chris on 04/07/2016.
//  Copyright © 2016 Whealy, Chris. All rights reserved.
//

import Foundation


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Basic computation tree node
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class Node {
  var value        : Double?
  var opCode       : String?
  var opIsImplicit : Bool = false
  var leftChild    : Node?
  var rightChild   : Node?

  // Node contains a value
  init(value: Double) {
    self.value  = value
    self.opCode = nil
  }

  // Node contains an operation
  init(opCode: String) {
    self.value  = nil
    self.opCode = opCode
  }

  // Node contains an operation
  init(opCode: String, value: Double) {
    self.value  = value
    self.opCode = opCode
  }

  func addLeftChild(childNode: Node)  -> Node { self.leftChild  = childNode; return self }
  func addRightChild(childNode: Node) -> Node { self.rightChild = childNode; return self }
}


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extend node class to provide numeric evaluation
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
extension Node {
  func evaluate() -> Double? { return _evaluateNode() }

  // During evaluation, check for value first then the op code.
  // Doing it this way means we don't have to care about translating numeric symbols into values
  // since Node.value contains the value of the symbol held in Node.opCode
  private func _evaluateNode() -> Double? {
    var retVal: Double?

    // Does the node have a value?
    if let val = self.value {
      // Yup, so return the value and we're done
      retVal = val
    }
    // Get the node's opCode if there is one
    else if let thisOpCode = self.opCode {
      if let thisOp = operations[thisOpCode] {
        let leftChild = self.leftChild

        switch thisOp {
          case .MemoryFunction          : retVal = retrieveMemoryValue(thisOpCode)
          case .Random(let fn)          : retVal = fn()
          case .Constant(let val)       : retVal = val
          case .UnaryOperation(let fn)  : retVal = fn(leftChild!._evaluateNode()!)
          case .BinaryOperation(let fn) :
            if let rightChild = self.rightChild {
              retVal = fn(leftChild!._evaluateNode()!, rightChild._evaluateNode()!)
            }

          default: break
        }
      }
    }

    return retVal
  }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extend node class to provide printing
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
extension Node {
  func toString() -> String { return _toString() }

  // During toString rendering, check the opCode before checking the value, that way, we don't need
  // to care about whether we've encoutered a numeric symbol
  private func _toString() -> String {
    var retVal: String = "Err"

    // Does the node have an opCode?
    if let strTemp = self.opCode,
       let thisOp  = operations[strTemp] {
      // Translate key presses into the characters shown in the computation
      // This is needed because when the inverse button is active, the calculator performs a
      // different function than the one described by the button label
      let strVal = inverseOpCodes[strTemp] ?? strTemp

      switch thisOp {
        case .UnaryOperation  : retVal = isPostFixOperator(strVal)
                                         ? "(" + self.leftChild!._toString() + ")" + strVal
                                         : strVal + "(" + self.leftChild!._toString() + ")"
        case .BinaryOperation : retVal = self.leftChild!._toString() +
                                         (self.opIsImplicit ? "" : strVal) +
                                         (self.rightChild != nil ? self.rightChild!._toString() : "")
        default               : retVal = strVal
      }
    }
    // The node has no opCode, so get it's value if there is one
    else if let val = self.value {
      retVal = doubleToIntWithoutOverflow(val)
    }

    return retVal
  }
}


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extend node class to identify any variables it might use
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
extension Node {
  func usesVariables() -> Array<String> {
    // Remove duplicate variable names whilst preserving their order
    return _parseTreeForVariables().reduce([]) { !$0.contains($1) ? $0 + Array(arrayLiteral: $1) : $0 }
  }

  // Parse computation tree for variable names
  private func _parseTreeForVariables() -> Array<String> {
    var retVal = [String]()

    // Does the node have an opCode?
    if let thisOpCode = self.opCode where isOpCodeAVariable(thisOpCode) {
      retVal.append(thisOpCode)
    }
    // The node has no opCode, so check if any of the children contain opCodes
    else {
      if let leftChild  = self.leftChild  { retVal += leftChild._parseTreeForVariables() }
      if let rightChild = self.rightChild { retVal += rightChild._parseTreeForVariables() }
    }

    return retVal
  }
}

