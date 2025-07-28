//
//  AttachmentType.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/27/25.
//

import Foundation
import RealityKit
import SwiftUI

enum AttachmentType {
  case keypad
  case boxNote
  case file
}

struct AttachmentConfig {
  let position: SIMD3<Float>
  let lookAtY: Float?
  let rotationAngle: Float?
  let rotationAxis: SIMD3<Float>?
  
  init(
    position: SIMD3<Float>,
    lookAtY: Float? = nil,
    rotationAngle: Float? = nil,
    rotationAxis: SIMD3<Float>? = nil
  ) {
    self.position = position
    self.lookAtY = lookAtY
    self.rotationAngle = rotationAngle
    self.rotationAxis = rotationAxis
  }
}
