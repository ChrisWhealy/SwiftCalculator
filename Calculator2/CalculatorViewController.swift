//
//  ViewController.swift
//  Calculator
//
//  Created by Whealy, Chris on 07/06/2016.
//  Copyright © 2016 Whealy, Chris. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
  @IBOutlet private weak var display:             UILabel!
  @IBOutlet private weak var onScreenComputation: UILabel!

  @IBOutlet private weak var inverseIndicator: UILabel!
  @IBOutlet private weak var memIndicator:     UILabel!
  @IBOutlet private weak var pgmIndicator:     UILabel!

  @IBOutlet private weak var kIndicator:  UILabel!
  @IBOutlet private weak var k1Indicator: UILabel!
  @IBOutlet private weak var k2Indicator: UILabel!
  @IBOutlet private weak var k3Indicator: UILabel!
  @IBOutlet private weak var k4Indicator: UILabel!
  @IBOutlet private weak var k5Indicator: UILabel!
  @IBOutlet private weak var k6Indicator: UILabel!

  @IBOutlet private weak var degIndicator: UILabel!
  @IBOutlet private weak var radIndicator: UILabel!

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
  private var prevOperation       = ""
  private var varNameNeeded       = false

  private let inverseColour = UIColor(red: 0.86, green: 0.54, blue: 0.18, alpha: 1.0)
  private let lightGrey     = UIColor(red: 0.847, green: 0.847, blue: 0.847, alpha: 1)
  private let black         = UIColor.blackColor()

  private var onScreenDisplayValue: Double {
    get { return Double(display.text!)! }
    set { display.text = doubleToIntWithoutOverflow(newValue) }
  }

  // Handle potential overflow when converting doubles that are > Int.max to string
  private func doubleToIntWithoutOverflow(dbl: Double) -> String {
    return dbl <= Double(Int.max) && dbl % 1 == 0 ? String(Int(dbl)) : String(dbl)
  }

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
    let font:           UIFont? = UIFont(name: typeface, size:12)
    let fontSuper:      UIFont? = UIFont(name: typeface, size:9)
    let baselineOffset: Int     = 7

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
                              range:                         NSRange(location:t.offset,length:t.len))
      return labelStr
    }

    sqrLabel.attributedText = superscriptedLabels[0]
    logLabel.attributedText = superscriptedLabels[1]
    lnLabel.attributedText  = superscriptedLabels[2]
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Update the state of the various indicators
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  private func showMemoryIndicator(mem: Bool)  { memIndicator.textColor = mem ? black : lightGrey }
  private func showProgramIndicator(pgm: Bool) { pgmIndicator.textColor = pgm ? black : lightGrey }

  private func showKIndicators(kFlags: Array<Bool>) {
    let kLabels: Array<UILabel> = [k1Indicator, k2Indicator, k3Indicator, k4Indicator, k5Indicator, k6Indicator]

    _ = zip(kLabels, kFlags).map() { $0.0.textColor = $0.1 ? black : lightGrey }

    kIndicator.textColor = kFlags.reduce(false) { $0 || $1 } ? black : lightGrey
  }

  private func flipInverseIndicator(inv: Bool) { inverseIndicator.textColor = inv ? lightGrey : black }

  private func flipDegRadIndicators(degMode: Bool) {
    degIndicator.textColor = degMode ? black : lightGrey
    radIndicator.textColor = degMode ? lightGrey : black
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Reset calculator
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  private func resetAfterOperation() {
    flipInverseIndicator(true)

    showKIndicators(brain.kRegisterFlags)

    userIsTypingNumber  = false
    decimalPointPressed = false
    decimalDivisor      = 1.0
    inverse             = false
  }

  private func resetCalculator() {
    resetAfterOperation()

    onScreenDisplayValue     = 0.0
    onScreenComputation.text = " "
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// User presses one of the function keys
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  @IBAction private func performOperation(sender: UIButton) {
    let currentOperation = sender.currentTitle!

    debugPrint("ViewCtlr.performOperation() : Received operation: \(currentOperation)")

    // First process key presses that are not mathematical operations
    switch currentOperation {
      case "INV":
        flipInverseIndicator(inverse)
        inverse = !inverse

      case "MODE":
        degreeMode = !degreeMode
        flipDegRadIndicators(degreeMode)

      case "AC":
        // Inverse AC clears the K Registers
        if inverse {
          brain.clearKRegisters()
          resetAfterOperation()
        }
        else {
          resetCalculator()
          brain.resetBrain()
        }

      case "C":
        // if the user presses clear after pressing equals, then there is no last op to clear
        // so this is equivalent to pleass all clear
        if prevOperation == "=" {
          resetCalculator()
          brain.resetBrain()
        }
        else {
//          brain.clearLastOp()
        }

        onScreenDisplayValue = brain.result

      case "K in", "K out":
        brain.setOperand(onScreenDisplayValue)
        brain.setMemory(currentOperation)

      case "Set":
        varNameNeeded      = true
        userIsTypingNumber = false

      default:
        // Switch on the "userIsTypingNumber" flag when the user presses a numeric symbol
        if isNumericSymbol(currentOperation) {
          userIsTypingNumber = true
        }
        else if userIsTypingNumber {
          brain.setOperand(onScreenDisplayValue)
        }

        // Are we setting a variable?
        if isOpCodeAVariable(currentOperation) {
          // Yup, so has "Set" just been pushed?
          if varNameNeeded {
            brain.setOperand(onScreenDisplayValue)
            brain.setMemory(currentOperation)
            varNameNeeded = false
          }

          if userIsTypingNumber {
            brain.implicitMultiplication = true
          }

          userIsTypingNumber = false
        }

        // Tell the brain to think about the answer
        brain.buildComputationTree(currentOperation, inv: inverse, degMode: degreeMode)

        // Update the computation string
        onScreenComputation.text = brain.resultAsString + (brain.isPartialResult ? "…" : "=")

        // Update the display
        onScreenDisplayValue = brain.result
        
        resetAfterOperation()
    }

    // Update memory and program indicators
    showMemoryIndicator(brain.memHasContents)

    prevOperation = currentOperation
  }


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// User presses the decimal point key
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  @IBAction private func touchDecimalPoint(sender: UIButton) {
    debugPrint("ViewCtlr.touchDecimalPoint() : user pressed decimal point")
    decimalPointPressed = true
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// User presses a numeric key
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  @IBAction private func touchDigit(sender: UIButton) {
    decimalDivisor *= decimalPointPressed ? 10 : 1

    let inputValue = Double(sender.currentTitle!)! / decimalDivisor

    debugPrint("ViewCtlr.touchDigit() : user pressed \(sender.currentTitle!)")

    // If this digit is a K register index, then do not update the on screen display
    if brain.KIndexNeeded {
      debugPrint("ViewCtlr.touchDigit() : Digit is a K index")
      brain.setOperand(Double(sender.currentTitle!)!)
      onScreenDisplayValue = brain.result
      resetAfterOperation()
    }
    else {
      onScreenDisplayValue = !userIsTypingNumber || onScreenDisplayValue == 0.0
                             ? inputValue
                             : decimalPointPressed
                               ? onScreenDisplayValue + inputValue
                               : (onScreenDisplayValue * 10) + inputValue

      userIsTypingNumber = true
    }
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// User presses a program key
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

  @IBAction func programSave() {
    debugPrint("ViewCtlr.programSave()")
    brain.saveProgram()
    showProgramIndicator(brain.hasSavedProgram)
  }

  @IBAction func programRestore() {
    debugPrint("ViewCtlr.programRestore()")
    brain.restoreProgram()
    onScreenDisplayValue     = brain.result
    onScreenComputation.text = brain.resultAsString + "="
  }

  @IBAction func programClear() {
    debugPrint("ViewCtlr.programClear()")
    brain.clearProgram()
    showProgramIndicator(brain.hasSavedProgram)
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// User wants to display a graph
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
  debugPrint("ViewCtlr.shouldPerformSegueWithIdentifier() = \(brain.hasSavedProgram)")
  return brain.hasSavedProgram
}

override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  debugPrint("ViewCtlr.prepareForSegue() Using program \(brain.getSavedProgram?.toString())")

  if let graphVC = segue.destinationViewController as? GraphViewController {
    graphVC.program              = brain.getSavedProgram
    graphVC.navigationItem.title = brain.getSavedProgram?.toString()
  }
}



// End of ViewController
}













