//
//  SwitchDragGesture+GroundBounce.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit

// MARK: - 바닥 튀어오름 효과
extension SwitchDragGesture {
  
  /// 바닥에 고정된 HandleDetached에 손이 닿았을 때 살짝 튀어오르는 효과
  func applyGroundBounceEffect(to entity: Entity) {
    guard entity.components.has(PhysicsBodyComponent.self) else { return }
    
    let physicsBody = entity.components[PhysicsBodyComponent.self]!
    guard physicsBody.mode == .kinematic && !physicsBody.isAffectedByGravity else { return }
    
    // 쿨다운 시간 체크 (연속적인 튀어오름 방지)
    if let lastBounce = lastBounceTime {
      let timeSinceLastBounce = Date().timeIntervalSince(lastBounce)
      if timeSinceLastBounce < bounceCooldown {
        print("⏰ [튀어오름 쿨다운] \(String(format: "%.1f", bounceCooldown - timeSinceLastBounce))초 남음")
        return
      }
    }
    
    lastBounceTime = Date()
    let currentPosition = entity.position
    
    // 짧은 순간만 dynamic 모드로 변경하여 튀어오르게 한 후 즉시 복원
    Task { @MainActor in
      // 1. Dynamic 모드로 임시 변경
      var tempPhysicsBody = physicsBody
      tempPhysicsBody.mode = .dynamic
      tempPhysicsBody.isAffectedByGravity = true
      entity.components.set(tempPhysicsBody)
      
      // 2. 위쪽으로 작은 위치 이동으로 튀어오르게 함 (addForce 대신 직접 위치 조정)
      let bounceHeight: Float = 0.1 // 10cm 위로 튀어오름
      entity.position.y += bounceHeight
      
      print("⬆️ [바닥 튀어오름] HandleDetached가 살짝 튀어오름")
      
      // 3. 0.5초 후 다시 kinematic 모드로 복원
      try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
      
      // 4. 다시 바닥 고정 상태로 복원
      var restoredPhysicsBody = physicsBody
      restoredPhysicsBody.mode = .kinematic
      restoredPhysicsBody.isAffectedByGravity = false
      entity.components.set(restoredPhysicsBody)
      
      // 5. 바닥 위치로 안전하게 복원
      let safeFloorHeight: Float = 0.05 // 바닥에서 5cm 위
      entity.position = SIMD3<Float>(currentPosition.x, safeFloorHeight, currentPosition.z)
      
      print("🏠 [바닥 복원] HandleDetached가 바닥 위치로 안전하게 복원됨")
    }
  }
}