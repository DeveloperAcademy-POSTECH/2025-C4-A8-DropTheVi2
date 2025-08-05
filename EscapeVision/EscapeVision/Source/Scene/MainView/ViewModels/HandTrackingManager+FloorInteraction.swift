//
//  HandTrackingManager+FloorInteraction.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit

// MARK: - 바닥 상호작용 및 반발 시스템
extension HandTrackingManager {
  
  /// 바닥에서 손바닥 누르기 감지 및 반발 처리
  func handleFloorInteraction(handleDetached: Entity, handPosition: SIMD3<Float>?) {
    // HandleDetached가 바닥에 고정된 상태가 아니면 무시
    guard handleDetached.components.has(PhysicsBodyComponent.self) else { return }
    let physicsBody = handleDetached.components[PhysicsBodyComponent.self]!
    guard physicsBody.mode == .kinematic && !physicsBody.isAffectedByGravity else { return }
    
    // 손 위치가 없으면 무시
    guard let handPos = handPosition else { return }
    
    // HandleDetached와 손의 거리 확인
    let handlePosition = handleDetached.position
    let distance = length(handPos - handlePosition)
    
    // 손이 HandleDetached 근처에 있는지 확인 (50cm 이내)
    guard distance < 0.5 else { return }
    
    // 손이 HandleDetached보다 위에 있는지 확인 (누르는 동작)
    let isHandAbove = handPos.y > handlePosition.y
    guard isHandAbove else { return }
    
    // 손바닥 누르기 쿨다운 확인
    if let lastPushTime = lastHandPushTime {
      let timeSinceLastPush = Date().timeIntervalSince(lastPushTime)
      if timeSinceLastPush < handPushCooldown {
        return // 쿨다운 중
      }
    }
    
    // 손바닥 누르기 패턴 감지 (빠른 하향 움직임)
    let realHandTrackingManager = RealHandTrackingManager.shared
    if !realHandTrackingManager.isAnyHandPinching() {
      // 핀치가 아닌 상태에서의 누르기 동작
      performFloorBounce(handleDetached: handleDetached)
      lastHandPushTime = Date()
      
      print("🤚 [손바닥 누르기 감지] HandleDetached 반발 효과 적용")
    }
  }
  
  /// 바닥에서 반발 효과 적용 (위로 튀어오르기)
  private func performFloorBounce(handleDetached: Entity) {
    // 현재 위치에서 위로 튀어오르는 효과
    let currentPosition = handleDetached.position
    let bounceHeight: Float = 0.15  // 15cm 위로 튀어오르기
    let bouncePosition = SIMD3<Float>(
      currentPosition.x,
      currentPosition.y + bounceHeight,
      currentPosition.z
    )
    
    // kinematic 모드를 잠시 해제하고 물리적 반발 적용
    var physicsBody = handleDetached.components[PhysicsBodyComponent.self]!
    physicsBody.mode = .dynamic
    physicsBody.isAffectedByGravity = true
    handleDetached.components.set(physicsBody)
    
    // 즉시 위치 이동 후 위쪽 속도 적용
    handleDetached.position = bouncePosition
    
    // PhysicsMotionComponent로 위쪽 속도 적용
    if handleDetached.components.has(PhysicsMotionComponent.self) {
      var physicsMotion = handleDetached.components[PhysicsMotionComponent.self]!
      physicsMotion.linearVelocity = SIMD3<Float>(0, 0.5, 0)  // 위쪽으로 0.5m/s
      handleDetached.components.set(physicsMotion)
    } else {
      // PhysicsMotionComponent가 없으면 추가
      let physicsMotion = PhysicsMotionComponent(linearVelocity: SIMD3<Float>(0, 0.5, 0))
      handleDetached.components.set(physicsMotion)
    }
    
    // 반발 사운드 재생
    SoundManager.shared.playSound(named: "switchdrop", volume: 0.3)
    
    print("🚀 [반발 효과] HandleDetached를 \(String(format: "%.2f", bounceHeight))m 위로 튀어올림")
    
    // 1초 후 다시 바닥으로 떨어뜨리기
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
      
      // 아직 공중에 있으면 바닥으로 떨어뜨리기
      if handleDetached.position.y > 0.1 {
        dropToFloor(handleDetached: handleDetached)
        print("🏠 [자동 착지] 반발 후 바닥으로 재착지")
      }
    }
  }
  
  /// 손바닥 누르기 패턴 감지 (하향 움직임 + 비핀치 상태)
  func detectHandPushPattern(deltaTranslation: CGSize) -> Bool {
    // 큰 움직임 (손바닥 누르기나 휘저음)
    let deltaWidth = Float(deltaTranslation.width)
    let deltaHeight = Float(deltaTranslation.height)
    let totalDelta = sqrt(deltaWidth * deltaWidth + deltaHeight * deltaHeight)
    let isLargeMotion = totalDelta > 15.0  // 큰 움직임
    
    // 핀치 상태가 아님
    let realHandTrackingManager = RealHandTrackingManager.shared
    let isNotPinching = !realHandTrackingManager.isAnyHandPinching()
    
    return isLargeMotion && isNotPinching
  }
  
  /// 바닥 고정 상태에서 손 상호작용 처리
  func handleGroundedInteraction(handleDetached: Entity, deltaTranslation: CGSize) {
    // 바닥 고정 상태 확인
    guard handleDetached.components.has(PhysicsBodyComponent.self) else { return }
    let physicsBody = handleDetached.components[PhysicsBodyComponent.self]!
    guard physicsBody.mode == .kinematic && !physicsBody.isAffectedByGravity else { return }
    
    // 손바닥 누르기 패턴 감지
    if detectHandPushPattern(deltaTranslation: deltaTranslation) {
      let realHandTrackingManager = RealHandTrackingManager.shared
      if let handPosition = realHandTrackingManager.getCurrentHandPosition() {
        handleFloorInteraction(handleDetached: handleDetached, handPosition: handPosition)
      }
      print("🛡️ [손바닥 누르기 차단] 바닥 고정 상태에서 누르기 동작 무시 및 반발 처리")
      return
    }
    
    // 일반 움직임은 완전 무시
    print("🛡️ [바닥 보호] 바닥 고정 상태 - 모든 손 움직임 무시")
  }
}