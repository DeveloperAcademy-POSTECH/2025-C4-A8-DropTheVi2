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
    @Environment(RoomViewModel.self) private var viewModel
    @State private var showPasswordModal = false
    
    var body: some View {
        RealityView { content in
            await viewModel.setup()
            content.add(viewModel.rootEntity)
            
            // ARKit 상태 진단 로그
            print("🎯 [RoomImmersiveView] ARKit 세션 초기화 완료")
            print("📍 [현재 카메라] 위치: \(viewModel.currentCameraPosition)")
            print("➡️ [현재 카메라] 방향: \(viewModel.currentCameraForward)")
            
        } update: { content in
            // 손 추적 시스템 주기적 확인 및 활성화
            checkAndInitializeHandTracking(viewModel: viewModel)
            
            // 핀치 모드 업데이트 (HandleDetached를 손 위치로 부드럽게 이동)
            updatePinchModeIfActive(viewModel: viewModel)
            
            // 손 추적 상태 주기적 모니터링
            monitorHandTrackingStatus()
        }
        .gesture(
            TapGesture(showPasswordModal: $showPasswordModal)
                .targetedToAnyEntity()
                .onEnded { value in
                    if let entity = value.entity as? ModelEntity {
                        if let component = entity.components[HandleComponent.self] {
                            print("핸들 탭됨 - switchIndex: \(component.switchIndex)")
                        }
                    }
                }
        )
        .gesture(
            SwitchDragGesture(viewModel: viewModel)
        )
        .sheet(isPresented: $showPasswordModal) {
            PasswordModalView(isPresented: $showPasswordModal)
        }
        .onAppear {
            print("🚀 [RoomImmersiveView] onAppear - 몰입형 공간 시작")
            print("🖐️ [손 추적 기반 HandleDetached 제어 시스템]")
            print("   1. ARKit 머리 추적 대신 손의 월드좌표 변화량 사용")
            print("   2. 더 안정적이고 직관적인 조작")
            print("   3. HandleDetached를 드래그하여 이동")
            print("   4. 최대 이동 거리: ±1.5미터")
            print("   5. 손 움직임이 직접 HandleDetached 위치에 반영")
        }
        .onDisappear {
            print("🔚 [RoomImmersiveView] onDisappear - 몰입형 공간 종료")
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
