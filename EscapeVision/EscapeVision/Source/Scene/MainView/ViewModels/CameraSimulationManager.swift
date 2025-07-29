//
//  CameraSimulationManager.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit
import ARKit

@MainActor
final class CameraSimulationManager {
  static let shared = CameraSimulationManager()
  private init() {}
  
  // MARK: - Simulation Methods
  
  /// 시뮬레이터용 테스트 모드 활성화
  func activateTestMode(for cameraManager: CameraTrackingManager) {
    print("🧪 [테스트 모드] 시뮬레이터용 ARKit 시뮬레이션 활성화")
    
    // 시뮬레이터에서는 가상의 카메라 움직임 시뮬레이션
    cameraManager.setCameraPosition(SIMD3<Float>(0.0, 1.6, 0.0))
    cameraManager.setCameraTransform(matrix_identity_float4x4)
    cameraManager.setCameraVectors(
      forward: SIMD3<Float>(0, 0, -1),
      right: SIMD3<Float>(1, 0, 0)
    )
    
    // ARKit을 활성화 상태로 설정 (시뮬레이션)
    cameraManager.setARKitActive(true)
    
    print("✅ [테스트 모드] 가상 ARKit 활성화 완료")
    print("📍 [가상 카메라] 위치: \(cameraManager.currentCameraPosition)")
    
    // 시뮬레이터에서 간단한 카메라 움직임 시뮬레이션
    Task {
      await simulateCameraMovement(for: cameraManager)
    }
  }
  
  /// 시뮬레이터용 카메라 움직임 시뮬레이션
  private func simulateCameraMovement(for cameraManager: CameraTrackingManager) async {
    var angle: Float = 0.0
    
    while cameraManager.arkitActiveStatus {
      try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초마다
      
      await MainActor.run {
        angle += 0.01
        
        // 미세한 움직임 시뮬레이션
        let x = sin(angle) * 0.05
        let z = cos(angle) * 0.05
        
        cameraManager.setCameraPosition(SIMD3<Float>(x, 1.6, z))
        
        // CameraSensitivityManager를 통한 회전 계산
        let rotationMatrix = CameraSensitivityManager.shared.createSimulatorRotationMatrix(angle: angle)
        let cameraVectors = CameraSensitivityManager.shared.calculateSimulatorCameraVectors(angle: angle)
        
        let fullTransform = simd_float4x4(
          rotationMatrix.columns.0,
          rotationMatrix.columns.1,
          rotationMatrix.columns.2,
          SIMD4<Float>(x, 1.6, z, 1)
        )
        
        cameraManager.setCameraTransform(fullTransform)
        cameraManager.setCameraVectors(forward: cameraVectors.forward, right: cameraVectors.right)
        
        // 위치 변화 로그 (가끔씩만)
        if Int(angle * 100) % 100 == 0 {
          print("📍 [시뮬레이션] 카메라 위치: \(String(format: "%.3f,%.3f,%.3f", x, 1.6, z))")
        }
      }
    }
  }
  
  /// 강제 ARKit 활성화용 기본 카메라 움직임 시뮬레이션
  func simulateBasicCameraMovement(for cameraManager: CameraTrackingManager) async {
    var time: Float = 0.0
    print("🎭 [시뮬레이션] 기본 카메라 움직임 시작")
    
    while cameraManager.arkitActiveStatus {
      try? await Task.sleep(nanoseconds: 200_000_000) // 0.2초마다
      
      await MainActor.run {
        time += 0.2
        
        // 매우 미세한 움직임으로 카메라가 살아있음을 표시
        let microX = sin(time * 0.5) * 0.02  // ±2cm
        let microZ = cos(time * 0.3) * 0.02  // ±2cm
        let microY = sin(time * 0.1) * 0.01  // ±1cm (상하)
        
        cameraManager.setCameraPosition(SIMD3<Float>(microX, 1.6 + microY, 0.1 + microZ))
        
        // CameraSensitivityManager를 통한 방향 계산
        let yawAngle = sin(time * 0.2) * 0.5  // 약간 증가된 움직임
        let rotationMatrix = CameraSensitivityManager.shared.createSimulatorRotationMatrix(angle: yawAngle, amplificationFactor: 1.0)
        let cameraVectors = CameraSensitivityManager.shared.calculateSimulatorCameraVectors(angle: yawAngle, amplificationFactor: 1.0)
        
        cameraManager.setCameraVectors(forward: cameraVectors.forward, right: cameraVectors.right)
        
        // 변환 행렬도 업데이트
        let fullTransform = simd_float4x4(
          rotationMatrix.columns.0,
          rotationMatrix.columns.1,
          rotationMatrix.columns.2,
          SIMD4<Float>(microX, 1.6 + microY, 0.1 + microZ, 1)
        )
        
        cameraManager.setCameraTransform(fullTransform)
        
        // 주기적으로 상태 로그 (10초마다)
        if Int(time * 10) % 100 == 0 {
          let position = cameraManager.currentCameraPosition
          print("📍 [시뮬레이션] 카메라: \(String(format: "%.3f,%.3f,%.3f", position.x, position.y, position.z))")
        }
      }
    }
  }
  
  /// 강제 ARKit 활성화 (최후의 수단)
  func forceActivateARKit(for cameraManager: CameraTrackingManager) {
    print("⚡ [강제 활성화] ARKit 상태를 강제로 활성화합니다")
    
    // 기본 카메라 위치 설정 (사용자 눈높이, 약간 앞쪽)
    cameraManager.setCameraPosition(SIMD3<Float>(0.0, 1.6, 0.1))
    cameraManager.setCameraTransform(simd_float4x4(
      SIMD4<Float>(1, 0, 0, 0),
      SIMD4<Float>(0, 1, 0, 0),
      SIMD4<Float>(0, 0, 1, 0),
      SIMD4<Float>(0.0, 1.6, 0.1, 1)
    ))
    
    // 기본 방향 벡터 (정면 바라보기)
    cameraManager.setCameraVectors(
      forward: SIMD3<Float>(0, 0, -1),
      right: SIMD3<Float>(1, 0, 0)
    )
    
    // ARKit 강제 활성화
    cameraManager.setARKitActive(true)
    
    print("✅ [강제 활성화] ARKit 상태 활성화 완료")
    print("📍 [강제 카메라] 위치: \(cameraManager.currentCameraPosition)")
    print("➡️ [강제 방향] Forward: \(cameraManager.currentCameraForward), Right: \(cameraManager.currentCameraRight)")
    print("💡 [알림] 머리 추적은 제한적이지만 핸드 제스처는 완전히 작동합니다")
    
    // 간단한 카메라 움직임 시뮬레이션 시작
    Task {
      await simulateBasicCameraMovement(for: cameraManager)
    }
  }
  
  /// 수동 테스트 모드 (ARKit 실패 시 대체)
  func startManualTestMode(for cameraManager: CameraTrackingManager) {
    print("🧪 [수동 테스트 모드] 시작 - 핸드 제스처 전용 모드")
    
    // 메인 액터에서 즉시 실행
    cameraManager.setCameraPosition(SIMD3<Float>(0.0, 1.6, 0.0))
    cameraManager.setCameraTransform(matrix_identity_float4x4)
    
    // 기본 방향 벡터 (정면 바라보기)
    cameraManager.setCameraVectors(
      forward: SIMD3<Float>(0, 0, -1),
      right: SIMD3<Float>(1, 0, 0)
    )
    
    // ARKit 비활성화 상태로 설정
    cameraManager.setARKitActive(false)
    
    print("📍 [수동 모드] 고정 카메라 위치: \(cameraManager.currentCameraPosition)")
    print("➡️ [수동 모드] 기본 방향: Forward=\(cameraManager.currentCameraForward) Right=\(cameraManager.currentCameraRight)")
    print("💡 [수동 모드] 핸드 제스처만으로 완전한 조작이 가능합니다")
    print("   - 좌우 이동: 손을 좌우로 움직임 (6배 강화)")
    print("   - 상하 이동: 손을 위아래로 움직임 (4배 강화)")
    print("   - 앞뒤 이동: 손을 크게 위아래로 움직임")
  }
} 