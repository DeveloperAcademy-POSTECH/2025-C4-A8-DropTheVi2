//
//  AttachmentType.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/27/25.
//

import Foundation
import RealityKit
import SwiftUI

@Observable
final class PositionManager {
  static let shared = PositionManager()
  
  private init() {}
  
  private let configurations: [AttachmentType: AttachmentConfig] = [
    .keypad: AttachmentConfig(
      position: SIMD3(-0.83808, 0.97728, 1.10787),
      lookAtY: 1.37728,
      rotationAngle: .pi,
      rotationAxis: SIMD3(0, 1, 0)
    ),
    .boxNote: AttachmentConfig(
      position: SIMD3(-0.83808, 1.12728, 1.10787),
      lookAtY: 1.37728,
      rotationAngle: .pi,
      rotationAxis: SIMD3(0, 1, 0)
    ),
    .file: AttachmentConfig(
      position: SIMD3(-1.58947, 1.17728, 1.10787),
      lookAtY: 1.37728,
      rotationAngle: .pi,
      rotationAxis: SIMD3(0, 1, 0)
    )
  ]
  
  func applyConfiguration(
    to entity: ViewAttachmentEntity,
    type: AttachmentType,
    content: RealityViewContent
  ) {
    guard let config = configurations[type] else {
      print("위치 타입값 못찾음")
      return
    }
    entity.position = config.position
    
    if let lookAtY = config.lookAtY {
      entity.look(
        at: SIMD3(0, lookAtY, 0),
        from: config.position,
        relativeTo: nil
      )
    }
    
    if let angle = config.rotationAngle,
       let axis = config.rotationAxis {
      entity.orientation = simd_quatf(angle: angle, axis: axis)
    }
    
    content.add(entity)
  }
}
