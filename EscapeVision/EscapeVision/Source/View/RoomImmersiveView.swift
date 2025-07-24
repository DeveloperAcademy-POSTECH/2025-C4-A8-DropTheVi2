//
//  RoomImmersiveView.swift
//  EscapeTest
//
//  Created by 조재훈 on 7/13/25.
//

import Foundation
import SwiftUI
import RealityKit
import RealityKitContent

struct RoomImmersiveView: View {
  @State private var viewModel = RoomViewModel.shared
  @State private var showPasswordModal: Bool = false
  @State private var showMonitorModal: Bool = false
  private let keypadPosition = SIMD3<Float>(-1.17064, 1.79641, 1.24997) // Y축 +0.3
  private let machinePosition = SIMD3<Float>(1.69722, 1.86142, -0.54857) // 수면가스 기계 좌표
  private let monitorPosition = SIMD3<Float>(1.5092113, 1.5676245, -0.17031083) // 모니터 화면 위치 좌표
  private let particlePosition = SIMD3<Float>(0.79441, 0.57728, -0.60016) // 파티클 좌표
  
  private let particleManager = ParticleManager.shared
  
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
      
      if let machineAttachment = attachments.entity(for: "Machine_Test") {
        machineAttachment.position = machinePosition
        machineAttachment.look(at: SIMD3(0, machinePosition.y, 0), from: machinePosition, relativeTo: nil)
        
        let totalAngle: Float = (-90.0 + 14.72) * .pi / 180
        machineAttachment.orientation = simd_quatf(angle: totalAngle, axis: SIMD3(0, 1, 0))
        
        content.add(machineAttachment)
      }
      
      if let monitorAttachment = attachments.entity(for: "Monitor") {
        monitorAttachment.position = monitorPosition
        monitorAttachment.look(at: SIMD3(0, monitorPosition.y, 0), from: monitorPosition, relativeTo: nil)
        
        content.add(monitorAttachment)
      }
    } attachments: {
      // 3D 공간에 배치될 키패드 첨부
      Attachment(id: "keypad") {
        if showPasswordModal {
          PasswordModalView(isPresented: $showPasswordModal)
          
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .glassBackgroundEffect()
        }
      }
      
      Attachment(id: "Machine_Test") {
        if showMonitorModal {
          GasMonitorView { isActive in
            if isActive {
              particleManager.playParticle(at: particlePosition)
            }
          }
        }
      }
    }
    .task {
      await viewModel.setup()
    }
    .gesture(
      TapGesture(target: "Plane_008", showModal: $showPasswordModal)
    )
    .simultaneousGesture(
      TapGesture(target: "Cube_005", showModal: $showMonitorModal)
    )
  }
}
