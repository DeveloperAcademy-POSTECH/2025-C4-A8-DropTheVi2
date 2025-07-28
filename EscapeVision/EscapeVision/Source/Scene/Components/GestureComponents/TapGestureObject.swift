//
//  TapGestureFile.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/27/25.
//

import SwiftUI

struct TapGestureObject: Gesture {
  
  private let soundManager = SoundManager.shared
  
  var target: String
  
  var body: some Gesture {
    SpatialTapGesture()
      .targetedToAnyEntity()
      .onEnded { value in
        if value.entity.name.contains(target) {
          objectTap(for: target)
        }
      }
  }
  
  private func objectTap(for target: String) {
    switch target {
    case "J_2b17_001":
      print("문고리 클릭됨")
      soundManager.playSound(.doorTap, volume: 1.0)
    case "Sphere_004":
      print("서랍 클릭됨")
      NotificationCenter.default.post(name: NSNotification.Name("openDrawer"), object: nil)
    case "Cube_007":
      print("서랍 손잡이 클릭됨")
    default:
      break
    }
  }
}
