//
//  GraphView.swift
//  Calculator2
//
//  Created by Whealy, Chris on 20/07/2016.
//  Copyright © 2016 Whealy, Chris. All rights reserved.
//


import UIKit

@IBDesignable

class GraphView: UIView {
  @IBInspectable var pointsPerUnit: CGFloat = 20
  @IBInspectable var axisColour   : UIColor = UIColor.blueColor()  { didSet { setNeedsDisplay() } }
  @IBInspectable var plotColour   : UIColor = UIColor.blackColor() { didSet { setNeedsDisplay() } }

  var pgm : Node? = nil { didSet { setNeedsDisplay() } }

  func changeScale(recognizer: UIPinchGestureRecognizer) {
    switch recognizer.state {
      case .Changed, .Ended:
        pointsPerUnit *= recognizer.scale
        recognizer.scale = 1.0

      default: break
    }
  }

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Override default draw method for view
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  override func drawRect(rect: CGRect) {
    debugPrint("GraphView.drawRect() Using program \(pgm?.toString())")

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Draw axes
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    let axes = AxesDrawer(color: axisColour, contentScaleFactor: UIScreen.mainScreen().scale)

    axes.drawAxesInRect(bounds,
                        origin: CGPoint(x: rect.midX, y: rect.midY),
                        pointsPerUnit: pointsPerUnit)

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // If there's a program in memory, then plot it's curve
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if let graphFn = pgm?.asFunction() {
      // Plot graph using the first encountered variable name as the X axis
      let usedVariables = pgm!.usesVariables()
      debugPrint("GraphView.drawRect() Found variables \(usedVariables)")

      let graphInVar = usedVariables.count > 0 ? String(usedVariables[0]) : "x"

      // Lets make life simpler for ourselves by moving the context's origin to the visual
      // origin indicated by the axes we've just plotted
      let ctx = UIGraphicsGetCurrentContext()

      let _ = usedVariables.map {
        debugPrint("GraphView.drawRect() Value in memory[\(String($0))] = \(memory[String($0)])")
      }

      let oldValue = memory[graphInVar]

      CGContextSaveGState(ctx)

      // Shift the origin
      CGContextTranslateCTM(ctx, bounds.midX, bounds.midY)

      let unitsPerPoint = 1 / pointsPerUnit

      let plotPath  = UIBezierPath()
      let plotWidth = Int(bounds.width)

      // Calculate graph
      let plot: Array<CGPoint> = {
        var tmp = [CGPoint]()

        // Calculate range over which to plot graph
        var x: CGFloat = -(bounds.width  / pointsPerUnit / 2)

        memory[graphInVar] = Double(x)

        // Calculate squares
        for _ in 0..<plotWidth {
          tmp.append(CGPoint(x: x * pointsPerUnit, y: -CGFloat(graphFn()!) * pointsPerUnit))
          x = round(1000 * (x + unitsPerPoint)) / 1000
          memory[graphInVar] = Double(x)
        }

        memory[graphInVar] = oldValue
        return tmp
      }()

      plotPath.moveToPoint(plot[0])

      // Define the graph's path
      for i in 1..<plot.count { plotPath.addLineToPoint(plot[i]) }

      plotColour.set()

      plotPath.lineWidth = 2.0
      plotPath.stroke()

      // Move the view's origin back to where it was
      CGContextRestoreGState(ctx)
    }
  }
}


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extend node class to provide a function that when called, evaluates the node
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
extension Node {
  func asFunction() -> () -> Double? { return _evaluateNodeAsFunction() }

  // During evaluation, check for value first then the op code.
  // Doing it this way means we don't have to care about translating numeric symbols into values
  // since Node.value contains the value of the symbol held in Node.opCode
  private func _evaluateNodeAsFunction() -> () -> Double? {
    var retFn: () -> Double? = { () in nil }

    // Does the node have a value?
    if let val = self.value {
      // Yup, so return the value wrapped in a function and we're done
      retFn = { () -> Double? in val }
    }
    // Get the node's opCode if there is one
    else if let thisOpCode = self.opCode {
      if let thisOp = operations[thisOpCode] {
        let leftChild = self.leftChild

        switch thisOp {
          case .MemoryFunction          : retFn = retrieveMemoryValueAsFunction(thisOpCode)
          case .Random(let fn)          : retFn = { () -> Double? in fn() }
          case .Constant(let val)       : retFn = { () -> Double? in val }
          case .UnaryOperation(let fn)  : retFn = { () -> Double? in fn((leftChild?._evaluateNodeAsFunction()()!)!) }
          case .BinaryOperation(let fn) :
            if let rightChild = self.rightChild {
              retFn = { () -> Double? in fn(leftChild!._evaluateNodeAsFunction()()!,
                                            rightChild._evaluateNodeAsFunction()()!)
                      }
            }

          default: break
        }
      }
    }

    return retFn
  }
}


