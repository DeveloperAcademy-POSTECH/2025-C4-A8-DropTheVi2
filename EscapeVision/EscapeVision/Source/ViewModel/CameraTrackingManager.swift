//
//  CameraTrackingManager.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit
import ARKit

@MainActor
@Observable
final class CameraTrackingManager {
  static let shared = CameraTrackingManager()
  private init() {}
  
  // ARKit 세션 및 카메라 추적을 위한 속성들
  private var arkitSession: ARKitSession?
  private var worldTrackingProvider: WorldTrackingProvider?
  private var handTrackingProvider: HandTrackingProvider?
  private var isARKitActive: Bool = false
  
  // 사용자 머리 방향 정보 (실시간 업데이트)
  var currentCameraTransform: simd_float4x4 = matrix_identity_float4x4
  var currentCameraForward: SIMD3<Float> = SIMD3<Float>(0, 0, -1)
  var currentCameraRight: SIMD3<Float> = SIMD3<Float>(1, 0, 0)
  var currentCameraPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
  private var lastLoggedPosition: SIMD3<Float> = SIMD3<Float>(999, 999, 999)
  
  // MARK: - Public Interface
  
  // Setter methods for external managers
  func setCameraPosition(_ position: SIMD3<Float>) {
    self.currentCameraPosition = position
  }
  
  func setCameraTransform(_ transform: simd_float4x4) {
    self.currentCameraTransform = transform
  }
  
  func setCameraVectors(forward: SIMD3<Float>, right: SIMD3<Float>) {
    self.currentCameraForward = forward
    self.currentCameraRight = right
  }
  
  func setARKitActive(_ active: Bool) {
    self.isARKitActive = active
  }
  
  var arkitActiveStatus: Bool {
    return self.isARKitActive
  }
  
  func setupARKitSession() async {
    print("🚀 [ARKit 초기화] 시작...")
    print("📋 [시스템 확인] visionOS 버전: \(ProcessInfo.processInfo.operatingSystemVersionString)")
    
    // 모든 권한 요청 먼저 진행
    print("🔐 [권한 요청] 모든 필요한 권한 요청 중...")
    await PermissionsManager.shared.requestAllPermissions()
    
    arkitSession = ARKitSession()
    worldTrackingProvider = WorldTrackingProvider()
    handTrackingProvider = HandTrackingProvider()
    
    guard let session = arkitSession,
          let provider = worldTrackingProvider,
          let handProvider = handTrackingProvider else {
      print("❌ [ARKit 초기화] 세션 생성 실패")
      CameraSimulationManager.shared.startManualTestMode(for: self)
      return
    }
    
    print("✅ [ARKit 세션] 생성 성공 (WorldTracking + HandTracking)")
    
    // 권한 상태 확인
    let permissionsManager = PermissionsManager.shared
    let permissionStatuses = permissionsManager.permissionStatuses
    
    print("📊 [권한 상태 확인] \(permissionStatuses)")
    
    // ARKit World Sensing + Hand Tracking 권한 재확인
    let arkitSession = ARKitSession()
    do {
      let authorizationResult = await arkitSession.requestAuthorization(for: [.worldSensing, .handTracking])
      let hasWorldSensing = authorizationResult[.worldSensing] == .allowed
      let hasHandTracking = authorizationResult[.handTracking] == .allowed
      
      if !hasWorldSensing {
        print("⚠️ [ARKit] World Sensing 권한이 없어 수동 모드로 전환")
        print("🔧 [권한 설정 방법]")
        print("   1. 설정 > 개인정보보호 > World Sensing")
        print("   2. 앱 권한에서 EscapeVision 허용")
        print("   3. 앱 재시작")
        CameraSimulationManager.shared.startManualTestMode(for: self)
        return
      }
      
      if !hasHandTracking {
        print("⚠️ [ARKit] Hand Tracking 권한이 없음 - 손 위치 추정 모드 사용")
        print("🔧 [핸드 트래킹 설정 방법]")
        print("   1. 설정 > 개인정보보호 > Hand Tracking")
        print("   2. 앱 권한에서 EscapeVision 허용")
        print("   3. 핀치는 카메라 기준 위치로 동작")
      } else {
        print("✅ [ARKit] Hand Tracking 권한 확인됨")
        // RealHandTrackingManager에 HandTracking 활성화 알림
        RealHandTrackingManager.shared.setHandTrackingActive(true)
      }
      
      print("✅ [ARKit] World Sensing 권한 확인됨")
      
    } catch {
      print("❌ [ARKit 권한] 확인 실패: \(error)")
      CameraSimulationManager.shared.startManualTestMode(for: self)
      return
    }
    
    // ARKit 세션 시작
    print("▶️ [ARKit 세션] 시작 시도...")
    do {
      // HandTracking이 활성화되어 있으면 함께 실행
      if RealHandTrackingManager.shared.handTrackingActiveStatus {
        try await session.run([provider, handProvider])
        print("✅ [ARKit 세션] 시작 성공 (WorldTracking + HandTracking)")
        print("ℹ️ [추적 시작] 월드 트래킹 + 핸드 트래킹 동시 진행")
        
        // RealHandTrackingManager에 HandTrackingProvider 설정 및 시작
        RealHandTrackingManager.shared.setHandTrackingProvider(handProvider)
        Task {
          await RealHandTrackingManager.shared.startHandTracking()
        }
      } else {
        try await session.run([provider])
        print("✅ [ARKit 세션] 시작 성공 (WorldTracking만)")
        print("ℹ️ [카메라 추적] 월드 트래킹 시작")
      }
      
      // 실시간 월드 트래킹 시작
      Task {
        await trackWorldUpdatesImproved()
      }
      
    } catch {
      print("❌ [ARKit 세션] 시작 실패: \(error)")
      print("🔧 [오류 분석] \(error.localizedDescription)")
      print("💡 [가능한 원인]")
      print("   1. Entitlements 파일 누락 또는 잘못된 설정")
      print("   2. 개발자 프로필 문제")  
      print("   3. Vision Pro 환경 문제 (조명, 공간)")
      print("   4. World Sensing 권한이 거부됨")
      isARKitActive = false
      CameraSimulationManager.shared.startManualTestMode(for: self)
    }
  }
  
  /// RealityView에서 직접 카메라 정보를 업데이트하는 메서드
  func updateCameraFromRealityView(transform: simd_float4x4, position: SIMD3<Float>) {
    // 유효한 위치인지 확인 (0,0,0이 아닌 실제 추적 데이터)
    if length(position) > 0.05 {
      self.currentCameraTransform = transform
      self.currentCameraPosition = position
      
      // 방향 벡터 계산
      let forward = -SIMD3<Float>(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
      let right = SIMD3<Float>(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z)
      
      self.currentCameraForward = normalize(forward)
      self.currentCameraRight = normalize(right)
      
      // ARKit 활성화 상태로 변경
      if !self.isARKitActive {
        self.isARKitActive = true
        print("✅ [ARKit 활성화] RealityView를 통한 카메라 추적 시작!")
      }
    }
  }
  
  // MARK: - Private Methods
  
    // 간단하고 직접적인 ARKit 활성화 (visionOS 시뮬레이터 대응)
  private func trackWorldUpdatesImproved() async {
    guard let session = arkitSession,
          let provider = worldTrackingProvider else {
      print("❌ [월드 트래킹] Session 또는 Provider가 없음 - 수동 모드로 전환")
      await MainActor.run {
        CameraSimulationManager.shared.startManualTestMode(for: self)
      }
      return
    }
    
        #if targetEnvironment(simulator)
    await MainActor.run {
       CameraSimulationManager.shared.activateTestMode(for: self)
    }
    return
    #endif
    
    // 실제 기기에서 3번 시도
    for attempt in 1...3 {
      try? await Task.sleep(nanoseconds: 5_000_000_000)
      let trackingResult = await tryRealTimeTracking(timeout: 10.0)
      if trackingResult {
        return
      }
    }
    
    // 실패 시 강제 활성화
    await MainActor.run {
      CameraSimulationManager.shared.forceActivateARKit(for: self)
    }
  }
  
  // 실제 기기용 실시간 추적 시도 (단순화된 버전)
  private func tryRealTimeTracking(timeout: Double) async -> Bool {
    guard let provider = worldTrackingProvider else { 
      print("❌ [실시간 추적] Provider 없음")
      return false 
    }
    
    print("🎯 [실시간 추적] \(timeout)초 동안 시도...")
    
    // 단순한 타임아웃과 추적 시도
    let startTime = Date()
    var foundValidData = false
    
    let trackingTask = Task {
      do {
        for await update in provider.anchorUpdates {
          let anchor = update.anchor
          let deviceTransform = anchor.originFromAnchorTransform
          let newPosition = SIMD3<Float>(deviceTransform.columns.3.x, deviceTransform.columns.3.y, deviceTransform.columns.3.z)
          
          print("🔍 [추적 데이터] 위치: \(newPosition), 길이: \(length(newPosition))")
          
          if length(newPosition) > 0.05 {
            await MainActor.run {
              print("✅ [유효한 데이터] ARKit 추적 활성화!")
              self.updateCameraInfo(transform: deviceTransform, position: newPosition)
              self.isARKitActive = true
            }
            foundValidData = true
            break
          }
          
          // 타임아웃 체크
          if Date().timeIntervalSince(startTime) > timeout {
            break
          }
        }
      } catch {
        print("❌ [실시간 추적] 오류: \(error)")
      }
    }
    
    // 타임아웃 대기
    try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    trackingTask.cancel()
    
    return foundValidData
  }
  
  // 실시간 추적 (폴링 성공 후)
  private func startRealTimeTracking() async {
    guard let provider = worldTrackingProvider else { return }
    
    print("🎯 [실시간 추적] 시작...")
    
    do {
      for await update in provider.anchorUpdates {
        await MainActor.run {
          let anchor = update.anchor
          let deviceTransform = anchor.originFromAnchorTransform
          let newPosition = SIMD3<Float>(deviceTransform.columns.3.x, deviceTransform.columns.3.y, deviceTransform.columns.3.z)
          
          if length(newPosition) > 0.05 {
            self.updateCameraInfo(transform: deviceTransform, position: newPosition)
          }
        }
      }
    } catch {
      print("❌ [실시간 추적] 오류: \(error)")
      await MainActor.run {
        CameraSimulationManager.shared.startManualTestMode(for: self)
      }
    }
  }
  
  // 카메라 정보 업데이트 공통 메서드 (감도 증폭 포함)
  private func updateCameraInfo(transform: simd_float4x4, position: SIMD3<Float>) {
    // 감도 매니저를 통한 증폭 적용
    let amplifiedTransform = CameraSensitivityManager.shared.applySensitivityAmplification(transform: transform)
    
    self.currentCameraTransform = amplifiedTransform
    self.currentCameraPosition = position
    
    // 방향 벡터 계산 (증폭된 변환에서)
    let forward = -SIMD3<Float>(amplifiedTransform.columns.2.x, amplifiedTransform.columns.2.y, amplifiedTransform.columns.2.z)
    let right = SIMD3<Float>(amplifiedTransform.columns.0.x, amplifiedTransform.columns.0.y, amplifiedTransform.columns.0.z)
    
    self.currentCameraForward = normalize(forward)
    self.currentCameraRight = normalize(right)
    
    // 위치 변화가 작아도 로그 출력 (민감도 확인용)
    if distance(position, self.lastLoggedPosition) > 0.005 {
      print("📍 [ARKit 추적] 위치: \(String(format: "%.3f,%.3f,%.3f", position.x, position.y, position.z))")
      print("🔄 [카메라 업데이트] 위치: \(position)")
      self.lastLoggedPosition = position
    }
  }
  
  // Vision Pro 월드 트래킹 (기존 방법 - 백업용)
  private func trackWorldUpdates() async {
    guard let session = arkitSession,
          let provider = worldTrackingProvider else {
      print("❌ [월드 트래킹] Session 또는 Provider가 없음 - 수동 모드로 전환")
      await MainActor.run {
        CameraSimulationManager.shared.startManualTestMode(for: self)
      }
      return
    }
    
    print("🌍 [월드 트래킹] 시작...")
    
    // 15초 타이머 시작
    Task {
      try? await Task.sleep(nanoseconds: 15_000_000_000)
      await MainActor.run {
        if !self.isARKitActive {
          print("⚠️ [ARKit 최종 타임아웃] 15초 경과 - 수동 모드로 강제 전환")
          CameraSimulationManager.shared.startManualTestMode(for: self)
        }
      }
    }
    
    // 앵커 업데이트 추적
    do {
      for await update in provider.anchorUpdates {
        await MainActor.run {
          let anchor = update.anchor
          
          // 월드 앵커에서 디바이스 변환 추출
          let deviceTransform = anchor.originFromAnchorTransform
          let newPosition = SIMD3<Float>(deviceTransform.columns.3.x, deviceTransform.columns.3.y, deviceTransform.columns.3.z)
          
          // 유효한 추적 데이터인지 확인
          if length(newPosition) > 0.05 && 
             (deviceTransform.columns.0 != SIMD4<Float>(1,0,0,0) || 
              deviceTransform.columns.1 != SIMD4<Float>(0,1,0,0)) {
            
            self.currentCameraTransform = deviceTransform
            self.currentCameraPosition = newPosition
            
            // 카메라 정보 업데이트 (감도 증폭 포함)
            self.updateCameraInfo(transform: deviceTransform, position: newPosition)
            
            if !self.isARKitActive {
              self.isARKitActive = true
              print("✅ [ARKit 활성화] 추적 시작!")
              print("🔄 [감도 설정] 좌우 회전 5배 증폭, 상하 회전 2.5배 증폭")
            }
          }
        }
      }
    } catch {
      print("❌ [ARKit 추적] 오류 발생: \(error)")
      await MainActor.run {
        CameraSimulationManager.shared.startManualTestMode(for: self)
      }
    }
  }

  
} 