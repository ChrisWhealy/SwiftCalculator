//
//  ViewController.swift
//  Calculator
//
//  Created by Whealy, Chris on 07/06/2016.
//  Copyright © 2016 Whealy, Chris. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  @IBOutlet private weak var display:             UILabel!
  @IBOutlet private weak var onScreenComputation: UILabel!

  @IBOutlet private weak var inverseIndicator: UILabel!
  @IBOutlet private weak var memIndicator:     UILabel!
  @IBOutlet private weak var pgmIndicator:     UILabel!
  @IBOutlet private weak var degIndicator:     UILabel!
  @IBOutlet private weak var radIndicator:     UILabel!

  @IBOutlet private weak var sineLabel    :UILabel!
  @IBOutlet private weak var cosineLabel  :UILabel!
  @IBOutlet private weak var tangentLabel :UILabel!

  @IBOutlet private weak var sqrLabel :UILabel!
  @IBOutlet private weak var logLabel :UILabel!
  @IBOutlet private weak var lnLabel  :UILabel!

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Global variables
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  private var userIsTypingNumber  = false
  private var inverse             = false
  private var degreeMode          = true
  private var decimalPointPressed = false
  private var decimalDivisor      = 1.0
  private var computationStr      = ""
  private var prevOperation       = ""

  private var onScreenDisplayValue: Double {
    get { return Double(display.text!)! }
    set { display.text = doubleToIntWithoutOverflow(newValue) }
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Display strings used for inverse op codes
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  private let inverseOpCodes: Dictionary<String, String> = [
      "inv_log" : "10^",
      "inv_ln"  : "e^",
      "inv_1/x" : "!",
      "inv_sin" : "asin",
      "inv_cos" : "acos",
      "inv_tan" : "atan",
      "inv_√"   : "^2",
      "inv_×"   : "^",
      "inv_÷"   : "^1/"]

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Get an instance of the model
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  private var brain = CalculatorBrain()

  typealias LabelString = NSMutableAttributedString

  // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  // Set any label text requiring super- or subscripted characters
  // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  override func viewDidLoad() {
    let typeface:       String  = "HelveticaNeue-Italic"
    let font:           UIFont? = UIFont(name: typeface, size:17)
    let fontSuper:      UIFont? = UIFont(name: typeface, size:10)
    let baselineOffset: Int     = 7

    let inverseColour :UIColor = UIColor(red: 0.86, green: 0.54, blue: 0.18, alpha: 1.0)

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Set labels for trig function function keys
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    var trigLabelStrs = ["sin","cos","tan"].map() { (trigFn :String) -> LabelString in
      let temp = LabelString(string: "\(trigFn)-1", attributes: [NSFontAttributeName:font!])

      temp.setAttributes([NSFontAttributeName:            fontSuper!,
                          NSBaselineOffsetAttributeName:  baselineOffset,
                          NSForegroundColorAttributeName: inverseColour],
                         range: NSRange(location:3,length:2))
      return temp
    }

    sineLabel.attributedText    = trigLabelStrs[0];
    cosineLabel.attributedText  = trigLabelStrs[1];
    tangentLabel.attributedText = trigLabelStrs[2];

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Set labels for other function function keys
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    var superscriptedLabels = [("x2",1,1),
                               ("10x",2,1),
                               ("ex",1,1)].map() { (t: (labelText: String, offset: Int, len: Int)) -> LabelString in
      let labelStr = LabelString(string: t.labelText, attributes: [NSFontAttributeName:font!])
      labelStr.setAttributes([NSFontAttributeName:           fontSuper!,
                              NSBaselineOffsetAttributeName: baselineOffset],
                             range: NSRange(location:t.offset,length:t.len))
      return labelStr
    }

    sqrLabel.attributedText = superscriptedLabels[0]
    logLabel.attributedText = superscriptedLabels[1]
    lnLabel.attributedText  = superscriptedLabels[2]
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Update the state of the various indicators
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  private func showMemoryIndicator(mem: Bool) {
    memIndicator.textColor = mem ? UIColor.blackColor() : UIColor.lightGrayColor()
  }

  private func showProgramIndicator(pgm: Bool) {
    pgmIndicator.textColor = pgm ? UIColor.blackColor() : UIColor.lightGrayColor()
  }

  private func flipInverseIndicator(inv: Bool) {
    inverseIndicator.textColor = inv ? UIColor.lightGrayColor() : UIColor.blackColor()
  }

  private func flipDegRadIndicator(degMode: Bool) {
    degIndicator.textColor = degMode ? UIColor.blackColor() : UIColor.lightGrayColor()
    radIndicator.textColor = degMode ? UIColor.lightGrayColor() : UIColor.blackColor()
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Convert the saved program to a printed string
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  private func memOpCode(opCode: String) -> Bool {
    return ["M+","inv_M+","MR","inv_MR"].indexOf(opCode) != nil
  }

  private func isOpCodeNumeric(opCode: String) -> Bool {
    return ["π","e","Rnd"].indexOf(opCode) != nil
  }

  // Translate key presses into the characters shown in the computation
  // This is needed because when the inverse button is active, the calculator performs a
  // different function than the one described by the button label
  private func getDisplayString(keyPressed: String, inv: Bool) -> String {
    return inverseOpCodes[(inv ? "inv_" : "") + keyPressed] ?? keyPressed
  }

  // Handle potential overflow when converting doubles that are > Int.max to string
  private func doubleToIntWithoutOverflow(dbl: Double) -> String {
    return dbl <= Double(Int.max) && dbl % 1 == 0 ? String(Int(dbl)) : String(dbl)
  }

  // Create the text string representing the current computation
  private func formatComputationStr(oldStr: String,
                                    operand: Double,
                                    currentOperation: String) -> String {
    let valueFromScreen = doubleToIntWithoutOverflow(operand)
    var resultStr = oldStr

    // Did the value in the display get there by the user typing?
    if userIsTypingNumber {
      // Yes. Are we part way through a binary operation?
      if brain.isPartialResult {
        // Is the current operation unary?
        if brain.thisOpIsUnary {
          // Yes, so wrap the screen value in parentheses and place the operation
          // at the start
          print("Outcome 1")
          resultStr += currentOperation + "(" + valueFromScreen + ")"
        }
        else {
          // Should the current contents of the computation string be preserved?
          if prevOperation == "=" || brain.prevOpIsUnary {
            // No, just print the user value from the screen followed by the operation
            print("Outcome 2")
            resultStr = valueFromScreen + currentOperation
          }
          else {
            // Has the user pressed a constant or the random number key÷
            if isOpCodeNumeric(currentOperation) {
              print("Outcome 3")
              resultStr += currentOperation
            }
            else {
              print("Outcome 4")
              resultStr += valueFromScreen + currentOperation
            }
          }
        }
      }
      else {
        // No, so has the user pressed one constant buttons?
        if isOpCodeNumeric(currentOperation) {
          //print the symbol rather than the numeric value
          print("Outcome 5")
          resultStr += currentOperation
        }
        else {
          //print the new number entered by the user
          print("Outcome 6")
          resultStr += valueFromScreen
        }
      }
    }
    else {
      // No, so the value on the screen is the result of a calculation
      if brain.isPartialResult {
        print("Outcome 7")
        resultStr += currentOperation
      }
      else {
        if brain.thisOpIsUnary {
          print("Outcome 8")
          resultStr = currentOperation + "(" + oldStr + ")"
        }
        else {
          // Did the user press one of the momery buttons?
          if memOpCode(currentOperation) {
            print("Outcome 9")
            resultStr += currentOperation
          }
          else {
            // If the previous operation used some symbol such as a constant, a memory
            // function, a random number or a unary operator, then this symbol will already
            // be in the display and there's nothing to add to the computation string
            if !memOpCode(prevOperation) &&
               !isOpCodeNumeric(prevOperation) &&
               !brain.prevOpIsUnary {
              print("Outcome 10")
              resultStr += valueFromScreen
            }
            else {
              print("Outcome 11")
            }
          }

        }
      }
    }

    return resultStr
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Reset calculator
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  private func resetAfterOperation() {
    flipInverseIndicator(true)

    userIsTypingNumber  = false
    decimalPointPressed = false
    decimalDivisor      = 1.0
    inverse             = false
  }

  private func resetCalculator() {
    resetAfterOperation()

    onScreenDisplayValue     = 0.0
    onScreenComputation.text = " "
    computationStr           = ""
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// User presses one of the function keys
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  @IBAction private func performOperation(sender: UIButton) {
    let currentOperation        = sender.currentTitle!
    let currentDisplayOperation = getDisplayString(currentOperation, inv: inverse)

    print("\nThis operation: \(currentOperation)")

    // First process key presses that are not mathematical operations
    switch currentOperation {
      case "INV":
        flipInverseIndicator(inverse)
        inverse = !inverse

      case "MODE":
        degreeMode = !degreeMode
        flipDegRadIndicator(degreeMode)

      case "AC":
        resetCalculator()
        brain.resetBrain()

      case "C":
        // if the user presses clear after pressing equals, then there is no last op to clear
        // so this is equivalent to pleass all clear
        if prevOperation == "=" {
          resetCalculator()
          brain.resetBrain()
        }
        else {
          brain.clearLastOp()
        }

        onScreenDisplayValue = brain.result

      default:
        // Switch on the "userIsTypingNumber" flag for certain operations that have the
        // equivalent effect
        if currentOperation == "e"   ||
           currentOperation == "π"   ||
           currentOperation == "Rnd" ||
           currentOperation == "MR" {
          userIsTypingNumber = true
        }

        if userIsTypingNumber {
          brain.setOperand(onScreenDisplayValue)
        }

        // Tell the brain to think about the answer
        brain.performOperation(currentOperation, inv: inverse, degMode: degreeMode)

        // Update the computation string
        computationStr = formatComputationStr(computationStr,
                                              operand: onScreenDisplayValue,
                                              currentOperation: currentDisplayOperation)
        onScreenComputation.text! = computationStr + (brain.isPartialResult ? "…" : "=")

        // Update the display
        onScreenDisplayValue = brain.result

        resetAfterOperation()
    }

    // Update memory and program indicators
    showMemoryIndicator(brain.memHasContents)

    prevOperation = currentDisplayOperation
  }


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// User presses the decimal point key
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  @IBAction private func touchDecimalPoint(sender: UIButton) {
    print("User pressed decimal point")
    decimalPointPressed = true
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// User presses a numeric key
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  @IBAction private func touchDigit(sender: UIButton) {
    decimalDivisor *= decimalPointPressed ? 10 : 1

    let inputValue = Double(sender.currentTitle!)! / decimalDivisor

    print("\nUser pressed \(sender.currentTitle!)")

    onScreenDisplayValue = !userIsTypingNumber || onScreenDisplayValue == 0.0
                           ? inputValue
                           : decimalPointPressed
                             ? onScreenDisplayValue + inputValue
                             : (onScreenDisplayValue * 10) + inputValue

    userIsTypingNumber = true
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// User presses a program key
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  var savedProgram: [CalculatorBrain.ProgramStep] = []

  @IBAction func programClear() {
    savedProgram = []
    showProgramIndicator(false)
 }

  @IBAction func programSave() {
    savedProgram = brain.program
    showProgramIndicator(true)
  }

  @IBAction func programRestore() {
    if savedProgram.count > 0 {
      brain.program = savedProgram
      onScreenDisplayValue = brain.result
    }
  }

// End of ViewController
}













