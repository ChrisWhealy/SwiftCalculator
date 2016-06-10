//
//  ViewController.swift
//  Calculator
//
//  Created by Whealy, Chris on 07/06/2016.
//  Copyright © 2016 Whealy, Chris. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet private weak var display: UILabel!
  @IBOutlet private weak var inverseIndicator: UILabel!

  @IBOutlet private weak var degIndicator: UILabel!
  @IBOutlet private weak var radIndicator: UILabel!

  private var userIsInTheMiddleOfTyping = false
  private var inverse                   = false
  private var degreeMode                = true
  private var decimalPointPressed       = false
  private var decimalDivisor            = 1.0

  private var displayValue: Double {
    get {
      return Double(display.text!)!
    }
    set {
      // Handle potential overflow when newValue > Int.max
      display.text = newValue > Double(Int.max)
                     ? String(newValue)
                     : newValue % 1 == 0
                       ? String(Int(newValue))
                       : String(newValue)
    }
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Flip the state of the various indicators
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  private func flipInverseIndicator(inv: Bool) {
    inverseIndicator.textColor = inv ? UIColor.lightGrayColor() : UIColor.blackColor()
  }

  private func flipDegRadIndicator(degMode: Bool) {
    degIndicator.textColor = degMode ? UIColor.blackColor() : UIColor.lightGrayColor()
    radIndicator.textColor = degMode ? UIColor.lightGrayColor() : UIColor.blackColor()
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Get an instance of the model
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  private var brain = CalculatorBrain()

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// User presses one of the function keys
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  @IBAction private func performOperation(sender: UIButton) {
    if userIsInTheMiddleOfTyping {
      brain.setOperand(displayValue)
    }

    if let keyValue = sender.currentTitle {
      print("\(keyValue) pressed.")
      print("User is typing starts = \(userIsInTheMiddleOfTyping)")
      print("Decimal point pressed starts = \(decimalPointPressed)")

      switch keyValue {
        case "INV":
          flipInverseIndicator(inverse)
          inverse = !inverse
        case "MODE":
          degreeMode = !degreeMode
          flipDegRadIndicator(degreeMode)
          print("Degree mode now = \(degreeMode)")

        default:
          // Treat pressing the decimal point key as a special case
          if (keyValue == ".") {
            print("Handling decimal point key")
            decimalPointPressed = true

            if !userIsInTheMiddleOfTyping {
              displayValue = 0.0
              userIsInTheMiddleOfTyping = true
            }
          }
          else {
            brain.performOperation(keyValue, inv: inverse, degMode: degreeMode)
            displayValue = brain.result

            // Other than pressing decimal point, all flags are now reset
            userIsInTheMiddleOfTyping = false
            decimalPointPressed       = false
            decimalDivisor            = 1.0
            inverse                   = false

            flipInverseIndicator(true)
          }
      }
    }
  }


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// User presses a numeric key
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  @IBAction private func touchDigit(sender: UIButton) {
    if decimalPointPressed {
      decimalDivisor *= 10
    }

    let digitChar  = sender.currentTitle!
    let inputValue = Double(digitChar)! / decimalDivisor

    print("\(digitChar) pressed")

    displayValue = userIsInTheMiddleOfTyping
                   ? displayValue == 0.0
                     ? inputValue
                     : decimalPointPressed
                       ? displayValue + inputValue
                       : (displayValue * 10) + inputValue
                   : inputValue

    userIsInTheMiddleOfTyping = true
  }

// End of ViewController
}

