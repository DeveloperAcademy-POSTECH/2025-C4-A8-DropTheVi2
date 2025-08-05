//
//  HandTrackingManager+PinchMode.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit

// MARK: - 핀치 모드 제어
extension HandTrackingManager {
  
  /// 핀치 모드 활성화 (HandleDetached를 지정된 위치로 부름)
  func activatePinchMode(handWorldPosition: SIMD3<Float>, cameraForward: SIMD3<Float>, handleDetached: Entity) {
    guard isTracking else {
      print("⚠️ [핀치 모드] 손 추적이 비활성화 상태 - 핀치 모드 활성화 불가")
      return
    }
    
    // 바닥에 고정된 상태라면 즉시 동적 상태로 변경 (빠른 반응)
    if handleDetached.components.has(PhysicsBodyComponent.self) {
      let physicsBody = handleDetached.components[PhysicsBodyComponent.self]!
      if physicsBody.mode == .kinematic && !physicsBody.isAffectedByGravity {
        var newPhysicsBody = physicsBody
        newPhysicsBody.mode = .dynamic
        newPhysicsBody.isAffectedByGravity = true
        handleDetached.components.set(newPhysicsBody)
        print("🚀 [즉시 활성화] 바닥 고정 상태 해제 - 핀치 반응 향상")
      }
    }
    
    isPinchMode = true
    // 전달받은 위치를 그대로 목표 위치로 사용 (중복 계산 방지)
    targetHandPosition = handWorldPosition
    pinchBasePosition = handWorldPosition  // 드래그 기준 위치 저장
    
    let currentPosition = handleDetached.position
    let distance = length(targetHandPosition - currentPosition)
    
    print("🤏 [핀치 모드 활성화] HandleDetached 이동 시작")
    print("📍 [현재 위치] \(String(format: "%.3f,%.3f,%.3f", currentPosition.x, currentPosition.y, currentPosition.z))")
    print("🎯 [목표 위치] \(String(format: "%.3f,%.3f,%.3f", targetHandPosition.x, targetHandPosition.y, targetHandPosition.z))")
    print("📏 [이동 거리] \(String(format: "%.3f", distance))m")
  }
  
  /// 핀치 모드에서 손 위치 실시간 업데이트
  func updatePinchModeHandPosition(handWorldPosition: SIMD3<Float>, cameraForward: SIMD3<Float>) {
    guard isPinchMode else { return }
    
    // 전달받은 위치를 그대로 목표 위치로 사용 (중복 계산 방지)
    targetHandPosition = handWorldPosition
    pinchBasePosition = handWorldPosition  // 기준 위치도 함께 업데이트
  }
  
  /// 핀치 모드에서 상대적 이동 적용
  func updatePinchModeWithDelta(deltaMovement: SIMD3<Float>) {
    guard isPinchMode else { return }
    
    // 기준 위치에서 델타만큼 이동
    targetHandPosition = pinchBasePosition + deltaMovement
    
    print("🤏 [핀치 델타] 기준: \(String(format: "%.3f,%.3f,%.3f", pinchBasePosition.x, pinchBasePosition.y, pinchBasePosition.z))")
    print("🤏 [핀치 델타] 이동: \(String(format: "%.3f,%.3f,%.3f", deltaMovement.x, deltaMovement.y, deltaMovement.z))")
    print("🤏 [핀치 델타] 목표: \(String(format: "%.3f,%.3f,%.3f", targetHandPosition.x, targetHandPosition.y, targetHandPosition.z))")
  }
  
  /// 핀치 모드에서 부드러운 이동 업데이트
  func updatePinchMode(handleDetached: Entity, deltaTime: Float = 0.016) {
    guard isPinchMode else { return }
    
    // HandleDetached가 바닥에 고정된 상태인지 강화된 검사
    if handleDetached.components.has(PhysicsBodyComponent.self) {
      let physicsBody = handleDetached.components[PhysicsBodyComponent.self]!
      if physicsBody.mode == .kinematic && !physicsBody.isAffectedByGravity {
        // 바닥에 착지하여 고정된 상태 - 손 움직임에 반응하지 않음
        print("🛡️ [핀치 모드 차단] HandleDetached가 바닥에 고정된 상태 - 손 움직임 무시")
        // 핀치 모드 자동 해제하여 더 이상 업데이트되지 않도록 함
        deactivatePinchMode()
        return
      }
    }
    
    // 추가 안전장치: HandleDetached가 바닥 근처에 있고 속도가 거의 0이면 움직이지 않음
    let currentY = handleDetached.position.y
    if currentY < 0.5 { // 바닥에서 50cm 이내
      if let physicsBody = handleDetached.components[PhysicsBodyComponent.self] {
        let velocity = physicsBody.linearVelocity
        let speed = length(velocity)
        if speed < 0.1 { // 속도가 매우 느리면 바닥에 안착한 것으로 간주
          print("🛡️ [바닥 안착 감지] HandleDetached가 바닥에 안착 - 손 움직임 차단 (Y: \(String(format: "%.3f", currentY)), 속도: \(String(format: "%.3f", speed)))")
          deactivatePinchMode() // 핀치 모드 해제
          return
        }
      }
    }
    
    let currentPosition = handleDetached.position
    let direction = targetHandPosition - currentPosition
    let distance = length(direction)
    
    // 목표 위치에 가까우면 (3cm 이내) 핀치 위치 유지 모드
    if distance < 0.03 {
      handleDetached.position = targetHandPosition
      return  // 핀치 모드 유지하며 손을 따라다님
    }
    
    // 부드러운 이동 (exponential smoothing)
    let normalizedDirection = normalize(direction)
    let moveDistance = min(distance, smoothingSpeed * deltaTime)
    let newPosition = currentPosition + normalizedDirection * moveDistance
    
    // 핀치 모드에서는 더 큰 범위 허용
    let worldDistance = length(newPosition)
    if worldDistance > pinchModeMaxRange {
      print("🚨 [핀치 모드 제한] HandleDetached가 너무 멀리 이동하려 함 (\(String(format: "%.1f", worldDistance))m) - 제한된 위치로 조정")
      let limitedPosition = normalize(newPosition) * pinchModeMaxRange
      handleDetached.position = limitedPosition
      return
    }
    
    handleDetached.position = newPosition
    
    if distance > 0.1 {  // 10cm 이상 차이날 때만 로그
      print("🤏 [핀치 추적] 거리: \(String(format: "%.3f", distance))m, 새 위치: \(String(format: "%.3f,%.3f,%.3f", newPosition.x, newPosition.y, newPosition.z))")
    }
  }
  
  /// 핀치 모드 비활성화
  func deactivatePinchMode() {
    if isPinchMode {
      print("🤏 [핀치 모드 종료] 일반 손 추적 모드로 복귀")
    }
    isPinchMode = false
    pinchBasePosition = .zero  // 핀치 기준 위치 초기화
    targetHandPosition = .zero  // 목표 위치 초기화
  }
  
  /// 현재 핀치 모드 상태 확인
  var isPinchModeActive: Bool {
    return isPinchMode
  }
} 