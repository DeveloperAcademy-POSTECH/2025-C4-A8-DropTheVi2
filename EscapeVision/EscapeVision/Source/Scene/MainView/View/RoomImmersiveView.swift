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
  @State private var isVisible = false
  @State private var viewModel = RoomViewModel.shared
  @State private var attachModel = AttachViewModel.shared
  private let particleManager = ParticleManager.shared
  
  @State private var showMonitorModal: Bool = false
  
  private let machinePosition = SIMD3<Float>(1.69722, 1.86142, -0.54857) // 수면가스 기계 좌표
  private let controlMonitorPosition = SIMD3<Float>(1.7007, 0.94853, -0.58316) // 조작 모니터 화면 위치 좌표 y + 0.5
  private let patientMonitorPosition = SIMD3<Float>(1.62414, 1.21879, 0.05951) // 환자 모니터 화면 위치 좌표 y + 0.4
  private let particlePosition = SIMD3<Float>(0.79441, 0.57728, -0.60016) // 파티클 좌표
    
  var body: some View {
    RealityView {
      content,
      attachments in
      
      content.add(viewModel.rootEntity)
      
      if let keypadAttachment = attachments.entity(for: "keypad") {
        attachModel.attachEntity(
          keypadAttachment,
          type: .keypad,
          content: content
        )
      }
      
      if let noteAttachment = attachments.entity(for: "BoxNote") {
        attachModel.attachEntity(
          noteAttachment,
          type: .boxNote,
          content: content
        )
      }
      
      if let fileAttachment = attachments.entity(for: "File") {
        attachModel.attachEntity(
          fileAttachment,
          type: .file,
          content: content
        )
      }
      
      if let machineAttachment = attachments.entity(for: "Machine_Test") {
        machineAttachment.position = machinePosition
        machineAttachment.look(at: SIMD3(0, machinePosition.y, 0), from: machinePosition, relativeTo: nil)
        
        let totalAngle: Float = (-90.0 + 15) * .pi / 180
        machineAttachment.orientation = simd_quatf(angle: totalAngle, axis: SIMD3(0, 1, 0))
        content.add(machineAttachment)
      }
      
      if let controlMonitorAttachment = attachments.entity(for: "controlMonitor") {
        controlMonitorAttachment.position = controlMonitorPosition
        controlMonitorAttachment.look(
          at: SIMD3(0, controlMonitorPosition.y, 0),
          from: controlMonitorPosition, relativeTo: nil
        )
        controlMonitorAttachment.orientation = simd_quatf(angle: ((-90.0 + 15) * .pi / 180), axis: SIMD3(0, 1, 0))
        
        content.add(controlMonitorAttachment)
      }
      
      if let patientMonitorAttachment = attachments.entity(for: "patientMonitor") {
        patientMonitorAttachment.position = patientMonitorPosition
        patientMonitorAttachment.look(
          at: SIMD3(0, patientMonitorPosition.y, 0),
          from: patientMonitorPosition, relativeTo: nil
        )
        patientMonitorAttachment.orientation = simd_quatf(angle: (270 * .pi / 180), axis: SIMD3(0, 1, 0))
        
        content.add(patientMonitorAttachment)
      }
    } attachments: {
      // 3D 공간에 배치될 키패드 첨부
      Attachment(id: "keypad") {
        if attachModel.showPasswordModal {
          PasswordModalView(isPresented: $attachModel.showPasswordModal, inputPassword: "")
        }
      }
      Attachment(id: "BoxNote") {
        if viewModel.isPresented {
          NoteModalView()
        }
      }
      
      Attachment(id: "File") {
        if attachModel.showFileModal {
          FileModalView(isPresented: $attachModel.showFileModal)
        }
      }
      
      Attachment(id: "Machine_Test") {
        if showMonitorModal {
          GasMonitorView { isActive in
            if isActive {
              particleManager.playParticle(at: particlePosition)
            }
          }
          .frame(width: 1920, height: 1175)
        }
      }
      
      Attachment(id: "controlMonitor") {
        GasMonitorView()
          .aspectRatio(1920.0 / 1175.0, contentMode: .fit)
          .frame(width: 680)
      }
      
      Attachment(id: "patientMonitor") {
        GasMonitorView()
          .aspectRatio(1920.0 / 1175.0, contentMode: .fit)
          .frame(width: 700)
      }
    }
    .task {
      await viewModel.setup()
    }
    .simultaneousGesture(
      TapGesture(target: "Plane_008", showModal: $attachModel.showPasswordModal)
    )
    .simultaneousGesture(
      TapGestureFile(
        target: "__pastas_02_001",
        isPresented: $attachModel.showFileModal
      )
    )
    .simultaneousGesture(
      TapGestureObject(
        target: "J_2b17_001"
      )
    )
    .simultaneousGesture(
      TapGesture(target: "Cube_005", showModal: $showMonitorModal)
    )
  }
}
