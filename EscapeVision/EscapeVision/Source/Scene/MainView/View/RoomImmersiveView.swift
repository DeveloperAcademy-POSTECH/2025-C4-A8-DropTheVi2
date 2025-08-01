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
  @Environment(AppModel.self) private var appModel
  
  @State private var viewModel = RoomViewModel.shared
  
  @State private var attachModel = AttachViewModel.shared
  private var lightManager = LightManager.shared
  private let particleManager = ParticleManager.shared
  
  // Legacy 손 추적 모달 상태
  @State private var showPasswordModal = false
  
  private let machinePosition = SIMD3<Float>(1.23308, 1.05112, -0.69557) // 모니터 앞으로 띄우는 좌표
  @State private var showMonitorModal: Bool = false
  @State private var monitorOpacity: Double = 0.0
  private let controlMonitorPosition = SIMD3<Float>(1.6407, 1.04853, -0.58316) // 조작 모니터 화면 위치 좌표 y + 0.5
  private let patientMonitorPosition = SIMD3<Float>(1.56414, 1.25879, 0.02) // 환자 모니터 화면 위치 좌표 y + 0.4
  private let particlePosition = SIMD3<Float>(0.80041, 0.57728, -0.62416) // 파티클 좌표
  
  // 화이트아웃 시작 지점에서 해당 메서드 호출
  // lightManager.startDramaticWhiteOutEffect()
  
  var body: some View {
    RealityView { content, attachments in
      await viewModel.setup()
      content.add(viewModel.rootEntity)
      
      // ARKit 상태 진단 로그
      print("🎯 [RoomImmersiveView] ARKit 세션 초기화 완료")
      print("📍 [현재 카메라] 위치: \(viewModel.currentCameraPosition)")
      print("➡️ [현재 카메라] 방향: \(viewModel.currentCameraForward)")
      
      lightManager.setupWhiteOutLight(in: content)
      
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
        
        let totalAngle: Float = (-90.0 + 25) * .pi / 180
        machineAttachment.orientation = simd_quatf(angle: totalAngle, axis: SIMD3(0, 1, 0))
        content.add(machineAttachment)
      }
      
      if let controlMonitorAttachment = attachments.entity(for: "controlMonitor") {
        controlMonitorAttachment.position = controlMonitorPosition
        controlMonitorAttachment.look(
          at: SIMD3(0, controlMonitorPosition.y, 0),
          from: controlMonitorPosition, relativeTo: nil
        )
        controlMonitorAttachment.orientation = simd_quatf(angle: ((-90.0 + 14) * .pi / 180), axis: SIMD3(0, 1, 0))
        
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
    } update: { content, attachments in
      // 손 추적 시스템 주기적 확인 및 활성화
      checkAndInitializeHandTracking(viewModel: viewModel)
      
      // 핀치 모드 업데이트 (HandleDetached를 손 위치로 부드럽게 이동)
      updatePinchModeIfActive(viewModel: viewModel)
      
      // 손 추적 상태 주기적 모니터링
      monitorHandTrackingStatus()
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
              
              // Fade out 애니메이션
              withAnimation(.easeOut(duration: 1.0)) {
                monitorOpacity = 0.0
              }
              DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                
                showMonitorModal = false
              }
            }
          }
          .aspectRatio(1920.0 / 1175.0, contentMode: .fit)
          .frame(width: 1200)
          .transition(.opacity) // fade in/out만 사용
          .animation(.easeInOut(duration: 3.5), value: showMonitorModal)
        }
      }
      
      Attachment(id: "controlMonitor") {
        GasMonitorView()
          .aspectRatio(1920.0 / 1175.0, contentMode: .fit)
          .frame(width: 730)
      }
      
      Attachment(id: "patientMonitor") {
        Image("A7_Monitor")
          .resizable()
          .aspectRatio(1920.0 / 1350.0, contentMode: .fit)
          .frame(width: 700)
      }
    }
    // .task 블록에서 setup() 호출 제거 - RealityView 블록에서 이미 호출됨 (중복 방지)
    // .task {
    //   await viewModel.setup()
    // }
    .gesture(
      SwitchDragGesture(viewModel: viewModel)
    )
    .simultaneousGesture(
      TapGesture(target: "Plane_008", showModal: $attachModel.showPasswordModal)
        .targetedToAnyEntity()
        .onEnded { value in
          if let entity = value.entity as? ModelEntity {
            if let component = entity.components[HandleComponent.self] {
              print("핸들 탭됨 - switchIndex: \(component.switchIndex)")
            }
          }
        }
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
      TapGestureObject(
        target: "Sphere_004"
      )
    )
    .simultaneousGesture(
      TapGestureObject(
        target: "Cube_07"
      )
    )
    .simultaneousGesture(
      TapGesture(target: "Cube_008", showModal: $showMonitorModal)
    )
    .sheet(isPresented: $showPasswordModal) {
      PasswordModalView(isPresented: $showPasswordModal, inputPassword: "")
    }
    .onAppear {
      print("🚀 [RoomImmersiveView] onAppear - 몰입형 공간 시작")
      print("🖐️ [손 추적 기반 HandleDetached 제어 시스템]")
      print("   1. ARKit 머리 추적 대신 손의 월드좌표 변화량 사용")
      print("   2. 더 안정적이고 직관적인 조작")
      print("   3. HandleDetached를 드래그하여 이동")
      print("   4. 최대 이동 거리: ±1.5미터")
      print("   5. 손 움직임이 직접 HandleDetached 위치에 반영")
      
      // 🎯 openVent 알림 구독 추가 (기존 onAppear 내용에 추가)
      NotificationCenter.default.addObserver(
        forName: NSNotification.Name("openVent"),
        object: nil,
        queue: .main
      ) { _ in
        print("🎯 [WhiteOut 트리거] 01100 패턴 달성!")
        
        // 극적인 WhiteOut 효과 실행
        lightManager.startDramaticWhiteOutEffect {
          print("🎬 [WhiteOut 완료] 메인 메뉴로 전환")
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            print("🎬 [메뉴 전환] 5초 대기 완료 - 메인 메뉴로 이동")
            appModel.showMainMenu()
          }
        }
      }
    }
    .onDisappear {
      print("🔚 [RoomImmersiveView] onDisappear - 몰입형 공간 종료")
      
        // 1. 알림 구독 해제
        NotificationCenter.default.removeObserver(self)
        
        // 2. 매니저들 정리
        particleManager.stopParticle()
        lightManager.cleanup()
        
        // 3. 🧹 핵심: 모든 Entity 완전 제거
        Task { @MainActor in
          // rootEntity 완전 초기화
          viewModel.rootEntity.children.removeAll()
          viewModel.rootEntity.removeFromParent()
          viewModel.rootEntity = Entity()
          
          // viewModel 상태 리셋
          viewModel.isPresented = false
        }
        
        // 4. 로컬 상태 초기화
        showPasswordModal = false
        showMonitorModal = false
        monitorOpacity = 0.0
        
        // AttachModel 상태 리셋
        attachModel.showPasswordModal = false
        attachModel.showFileModal = false
        
        appModel.exitGame()
        
        print("✅ [완전 정리] 새 게임 준비 완료!")
    }
  }
  
  // MARK: - Helper Functions
  
  /// 손 추적 시스템 초기화 확인
  private func checkAndInitializeHandTracking(viewModel: RoomViewModel) {
    let handleManager = HandleManager.shared
    guard let handleDetached = handleManager.getHandleDetached() else {
      return  // HandleDetached가 없으면 아무것도 하지 않음
    }
    
    let handTrackingManager = HandTrackingManager.shared
    
    // 손 추적이 아직 시작되지 않았으면 시작
    if !handTrackingManager.isHandTracking {
      // 월드 좌표에서 위치 확인 (원점 기준이 아닌 실제 월드 위치)
      let worldPosition = handleDetached.convert(position: .zero, to: nil)
      let cameraPosition = viewModel.currentCameraPosition
      let distanceFromCamera = length(worldPosition - cameraPosition)
      
      print("🔍 [손 추적 검증] HandleDetached 월드 위치: \(worldPosition)")
      print("📍 [손 추적 검증] 카메라 위치: \(cameraPosition)")
      print("📏 [손 추적 검증] 카메라에서 거리: \(String(format: "%.3f", distanceFromCamera))m")
      
      // 거리가 너무 멀거나 (5m 이상) 원점에 너무 가까운 경우만 제외
      if length(worldPosition) < 0.1 {
        print("⚠️ [손 추적] HandleDetached가 원점에 있어 손 추적을 시작하지 않습니다")
        return
      }
      
      if distanceFromCamera > 5.0 {
        print("⚠️ [손 추적] HandleDetached가 너무 멀리 있어 손 추적을 시작하지 않습니다 (\(String(format: "%.1f", distanceFromCamera))m)")
        return
      }
      
      handTrackingManager.startHandTracking(for: handleDetached)
      print("✅ [손 추적 시스템] 활성화 완료 - HandleDetached 위치에서 손 움직임 제어 시작")
    }
  }
  
  /// 핀치 모드가 활성화되어 있으면 업데이트
  private func updatePinchModeIfActive(viewModel: RoomViewModel) {
    let handTrackingManager = HandTrackingManager.shared
    let handleManager = HandleManager.shared
    
    // 핀치 모드가 활성화되어 있고 HandleDetached가 존재하면 업데이트
    if handTrackingManager.isPinchModeActive,
       let handleDetached = handleManager.getHandleDetached() {
      handTrackingManager.updatePinchMode(handleDetached: handleDetached)
    }
  }
  
  /// 손 추적 상태 모니터링
  private func monitorHandTrackingStatus() {
    let handTrackingManager = HandTrackingManager.shared
    let handleManager = HandleManager.shared
    
    // 정적 변수로 로그 출력 빈도 제어
    struct LastLog {
      static var lastTime: Date = Date()
      static var lastStatus: Bool = false
      static var lastPinchStatus: Bool = false
    }
    
    let currentTime = Date()
    let timeSinceLastLog = currentTime.timeIntervalSince(LastLog.lastTime)
    let currentPinchStatus = handTrackingManager.isPinchModeActive
    
    // 5초마다 또는 상태가 변경될 때만 로그 출력
    if timeSinceLastLog > 5.0 ||
        LastLog.lastStatus != handTrackingManager.isHandTracking ||
        LastLog.lastPinchStatus != currentPinchStatus {
      
      let handleDetachedExists = handleManager.getHandleDetached() != nil
      
      print("🔄 [손 추적 모니터] 상태: \(handTrackingManager.isHandTracking ? "✅활성" : "❌비활성"), 핀치모드: \(currentPinchStatus ? "🤏활성" : "❌비활성"), HandleDetached존재: \(handleDetachedExists ? "✅" : "❌")")
      
      if !handTrackingManager.isHandTracking && handleDetachedExists {
        print("💡 [손 추적 가이드] HandleDetached를 찾아서 드래그하면 손 추적이 시작됩니다")
      }
      
      if currentPinchStatus {
        print("🤏 [핀치 가이드] HandleDetached가 손 위치로 이동 중입니다")
      }
      
      LastLog.lastTime = currentTime
      LastLog.lastStatus = handTrackingManager.isHandTracking
      LastLog.lastPinchStatus = currentPinchStatus
    }
  }
}

// MARK: - Extensions

extension SIMD4 {
  var xyz: SIMD3<Scalar> {
    return SIMD3<Scalar>(x, y, z)
  }
}
