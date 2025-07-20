//
//  TapGesture.swift
//  EscapeTest
//
//  Created by 조재훈 on 7/19/25.
//

import SwiftUI
import RealityKit

struct TapGesture: Gesture {
  
  @State private var viewModel = RoomViewModel.shared
  
  @Binding var showPasswordModal: Bool
  
  var body: some Gesture {
    SpatialTapGesture()
      .targetedToAnyEntity()
      .onEnded { value in
        lockTap(value)
      }
  }
  
  private func lockTap(_ value: EntityTargetValue<SpatialTapGesture.Value>) {
    if value.entity.name.contains("Plane_008") {
      print("비밀번호 입력 패널 클릭됨")
      DispatchQueue.main.async {
        showPasswordModal = true
        viewModel.playOpenLidAnimation()
        print("모달 상태 변경: \(showPasswordModal)")
      }
      
      
      
      
    }
  }
}
