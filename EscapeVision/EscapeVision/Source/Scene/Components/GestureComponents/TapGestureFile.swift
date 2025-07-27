//
//  TapGestureFile.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/27/25.
//

import SwiftUI

struct TapGestureFile: Gesture {
  
  var target: String
  @Binding var isPresented: Bool
  
  var body: some Gesture {
    SpatialTapGesture()
      .targetedToAnyEntity()
      .onEnded { value in
        if value.entity.name.contains(target) {
          fileTap(for: target)
        }
      }
  }
  
  private func fileTap(for target: String) {
    switch target {
    case "__pastas_02_001":
      print("File 클릭됨")
      isPresented = true
    default:
      break
    }
  }
}
