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
  
  // target에 따라 어떤 엔티티를 누른 건지 판단
  var target: String
  @Binding var showModal: Bool
   
  var body: some Gesture {
    SpatialTapGesture()
      .targetedToAnyEntity()
      .onEnded { value in
        if value.entity.name.contains(target) {
          handleTap(for: target)
        }
      }
  }
  
  private func handleTap(for target: String) {
    
      switch target {
      case "Plane_008":
        print("비밀번호 입력 패널 클릭됨")
        showModal = true
        print("모달 상태 변경: \(showModal)")
        
      case "Cube_005":
        print("모니터 패널 클릭됨")
        showModal.toggle()
        print("모달 상태 변경: \(showModal)")
        
      case "__pastas_02_001":
        print("File 클릭됨")
        showModal = true
        
      default:
        break
      }
  }
}
