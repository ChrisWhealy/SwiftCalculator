//
//  GraphViewController.swift
//  Calculator2
//
//  Created by Whealy, Chris on 20/07/2016.
//  Copyright © 2016 Whealy, Chris. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController {
  var program : Node? = nil { didSet { plotGraph() } }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Only called once at the start of the view controller's lifecycle
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  @IBOutlet weak var graphView: GraphView! {
    didSet {
      debugPrint("GraphViewController.graphView.didSet()")

      // Add recogniser for pinch gesture
      graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView,
                                                              action: #selector(GraphView.changeScale(_:))))

      // Initial screen draw
      plotGraph()
    }
  }

  private func plotGraph() {
    debugPrint("GraphViewController.plotGraph() using program \(program?.toString())")

    if graphView != nil &&
       program   != nil {
      graphView.pgm = program!
    }
  }
}

