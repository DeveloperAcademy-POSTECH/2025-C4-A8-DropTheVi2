//
//  RoomImmersiveView.swift
//  EscapeTest
//
//  Created by 조재훈 on 7/13/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct RoomImmersiveView: View {
  @State private var viewModel = RoomViewModel.shared
  @State private var showPasswordModal: Bool = false
  @State private var keypadPosition: SIMD3<Float> = SIMD3(-1.10256, 1.37728, 1.01941) // Y축 +0.3
  
  var body: some View {
    RealityView { content, attachments in
      content.add(viewModel.rootEntity)
      
      // 키패드를 3D 공간에 직접 배치
      if let keypadAttachment = attachments.entity(for: "keypad") {
        keypadAttachment.position = keypadPosition
        
        keypadAttachment.look(at: SIMD3(0, keypadPosition.y, 0), from: keypadPosition, relativeTo: nil)
        keypadAttachment.orientation = simd_quatf(angle: .pi, axis: SIMD3(0, 1, 0))
        
        content.add(keypadAttachment)
      }
    } attachments: {
      // 3D 공간에 배치될 키패드 첨부
      Attachment(id: "keypad") {
        if showPasswordModal {
          PasswordModalView(isPresented: $showPasswordModal, inputPassword: "")
            
//            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
//            .glassBackgroundEffect()
        }
      }
    }
    .task {
      await viewModel.setup()
    }
    .gesture(TapGesture(showPasswordModal: $showPasswordModal))
  }
}
