//
//  NSFWManager.swift
//  Tangerine
//
//  Created by Mahmudul Hasan on 2023-01-31.
//

import UIKit

class NSFWManager {
    
  static var shared = NSFWManager()

  private init(){

  }


  func checkNudityIn(image inputImage: UIImage) -> Double {

    let nsfw = nsfw_2()

    guard let buffer = inputImage.buffer(), let output = try? nsfw.prediction(data: buffer) else {
      fatalError("Unexpected runtime error.")
    }

    // Grab the result from prediction
    let proba = output.prob[1].doubleValue

    print("Nudity: \(String(format: "%.6f", proba * 100))%")

    return (proba * 100).rounded()

  }
}
