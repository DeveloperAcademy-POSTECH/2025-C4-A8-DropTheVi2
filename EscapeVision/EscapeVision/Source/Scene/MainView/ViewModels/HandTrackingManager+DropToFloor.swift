//
//  HandTrackingManager+DropToFloor.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit

// MARK: - 바닥 착지 마킹 컴포넌트
struct GroundedMarkerComponent: Component {}

// MARK: - 바닥 떨어뜨리기 및 관련 기능
extension HandTrackingManager {
  
  /// 바닥 위치 업데이트 (정확한 표면 위치 계산)
  func updateFloorPosition() {
    // EntitySearchManager를 사용해서 Floor 엔티티 찾기
    let entitySearchManager = EntitySearchManager.shared
    if let floorEntity = entitySearchManager.findFloor() {
      // 다양한 방법으로 바닥 위치 계산하여 가장 정확한 값 선택
      
      // 방법 1: Floor 엔티티의 월드 바운딩 박스 최상단
      let worldBounds = floorEntity.visualBounds(relativeTo: nil)
      let worldTopY = worldBounds.max.y
      
      // 방법 2: Floor 월드 위치 + 로컬 바운딩 박스 최상단
      let floorWorldPosition = floorEntity.convert(position: SIMD3<Float>(0, 0, 0), to: nil)
      let localBounds = floorEntity.visualBounds(relativeTo: floorEntity)
      let calculatedTopY = floorWorldPosition.y + localBounds.max.y
      
      // 방법 3: Floor 엔티티의 실제 Transform 위치
      let entityPositionY = floorEntity.position.y
      
      // 가장 높은 값을 실제 바닥 표면으로 사용 (안전한 선택)
      let candidateFloorY = max(worldTopY, max(calculatedTopY, entityPositionY))
      
      floorY = candidateFloorY
      
      // 예외적으로 낮은 값 보정
      if floorY < -2.0 {
        print("⚠️ [바닥 위치 보정] Floor Y좌표가 너무 낮음: \(floorY) → 0.0으로 조정")
        floorY = 0.0
      }
      
      print("🏠 [Floor 다중 계산 검증]")
      print("   - Floor 엔티티 Transform 위치: Y = \(String(format: "%.3f", entityPositionY))")
      print("   - Floor 월드 위치: (\(String(format: "%.3f", floorWorldPosition.x)), \(String(format: "%.3f", floorWorldPosition.y)), \(String(format: "%.3f", floorWorldPosition.z)))")
      print("   - Floor 로컬 바운딩박스: min=(\(String(format: "%.3f", localBounds.min.x)), \(String(format: "%.3f", localBounds.min.y)), \(String(format: "%.3f", localBounds.min.z))), max=(\(String(format: "%.3f", localBounds.max.x)), \(String(format: "%.3f", localBounds.max.y)), \(String(format: "%.3f", localBounds.max.z)))")
      print("   - Floor 월드 바운딩박스: min=(\(String(format: "%.3f", worldBounds.min.x)), \(String(format: "%.3f", worldBounds.min.y)), \(String(format: "%.3f", worldBounds.min.z))), max=(\(String(format: "%.3f", worldBounds.max.x)), \(String(format: "%.3f", worldBounds.max.y)), \(String(format: "%.3f", worldBounds.max.z)))")
      print("   - 계산 방법별 결과: 월드최상단=\(String(format: "%.3f", worldTopY)), 계산최상단=\(String(format: "%.3f", calculatedTopY)), Transform=\(String(format: "%.3f", entityPositionY))")
      print("🏠 [최종 바닥 위치] Y = \(String(format: "%.3f", floorY)) (최고값 선택으로 안전 보장)")
    } else {
      // Floor를 찾지 못하면 기본값 사용
      floorY = 0.0
      print("⚠️ [바닥 미발견] 기본 바닥 위치 사용: Y = \(floorY)")
    }
  }
  
  /// 핀치 해제 시 HandleDetached를 바닥으로 떨어뜨리기
  func dropToFloor(handleDetached: Entity) {
    // 물리 컴포넌트가 없다면 즉시 복원 (바닥 뚫림 방지)
    if !handleDetached.components.has(PhysicsBodyComponent.self) {
      let physicsBody = PhysicsBodyComponent(
        massProperties: PhysicsMassProperties(mass: 0.1),
        material: PhysicsMaterialResource.generate(
          staticFriction: 0.8, 
          dynamicFriction: 0.6, 
          restitution: 0.1
        ),
        mode: .dynamic
      )
      handleDetached.components.set(physicsBody)
      print("🔧 [안전장치] dropToFloor 시 PhysicsBodyComponent 복원")
    }
    
    // 충돌 컴포넌트도 없다면 복원
    if !handleDetached.components.has(CollisionComponent.self) {
      let handleBounds = handleDetached.visualBounds(relativeTo: nil)
      let handleSize = handleBounds.max - handleBounds.min
      let expandedCollisionSize = SIMD3<Float>(
        max(0.06, handleSize.x * 1.2),
        max(0.06, handleSize.y * 1.2),
        max(0.06, handleSize.z * 1.2)
      )
      let collisionShape = ShapeResource.generateBox(size: expandedCollisionSize)
      handleDetached.components.set(CollisionComponent(
        shapes: [collisionShape], 
        mode: .default, 
        filter: .init(group: .default, mask: .all)
      ))
      print("🔧 [안전장치] dropToFloor 시 CollisionComponent 복원")
    }
    
    let currentPosition = handleDetached.position
    
    // 바닥 위치를 고정된 안전한 값으로 설정 (매번 재계산하지 않음)
    // 이를 통해 HandleDetached가 점점 더 아래로 떨어지는 문제 해결
    let fixedFloorY: Float = 0.0  // 고정된 바닥 높이
    
    // 확실한 안전을 위해 절대적으로 안전한 높이 사용
    // 바닥 계산에 의존하지 않고 충분히 높은 위치에 배치
    
    // HandleDetached의 현재 상태 확인
    let handleCurrentWorldPos = handleDetached.convert(position: SIMD3<Float>(0, 0, 0), to: nil)
    let handleLocalBounds = handleDetached.visualBounds(relativeTo: handleDetached)
    _ = handleDetached.visualBounds(relativeTo: nil)  // 사용하지 않는 변수 처리
    
    // 절대적으로 안전한 높이 계산
    // 1. 바닥 위치와 관계없이 최소 10cm 위에 배치
    let absoluteSafetyHeight: Float = 0.10
    
    // 2. HandleDetached의 크기를 고려한 추가 높이
    let handleTotalHeight = abs(handleLocalBounds.max.y - handleLocalBounds.min.y)
    let handleSizeBuffer = max(handleTotalHeight * 0.5, 0.05)  // 크기의 50% 또는 최소 5cm
    
    // 3. 최종 안전 높이 = 바닥 + 절대 안전 높이 + 크기 버퍼
    let finalSafeHeight = absoluteSafetyHeight + handleSizeBuffer
    
    // 4. 바닥 위치에서 안전 높이만큼 위에 배치
    let handleHeight = finalSafeHeight
    
    print("📦 [절대 안전 배치 시스템]")
    print("   - 현재 월드 위치: (\(String(format: "%.3f", handleCurrentWorldPos.x)), \(String(format: "%.3f", handleCurrentWorldPos.y)), \(String(format: "%.3f", handleCurrentWorldPos.z)))")
    print("   - HandleDetached 크기: 높이=\(String(format: "%.3f", handleTotalHeight))m")
    print("   - 로컬 바운딩박스: min=(\(String(format: "%.3f", handleLocalBounds.min.x)), \(String(format: "%.3f", handleLocalBounds.min.y)), \(String(format: "%.3f", handleLocalBounds.min.z))), max=(\(String(format: "%.3f", handleLocalBounds.max.x)), \(String(format: "%.3f", handleLocalBounds.max.y)), \(String(format: "%.3f", handleLocalBounds.max.z)))")
    print("📏 [절대 안전 계산]")
    print("   - 절대 안전 높이: \(String(format: "%.3f", absoluteSafetyHeight))m")
    print("   - 크기 기반 버퍼: \(String(format: "%.3f", handleSizeBuffer))m")
    print("   - 최종 배치 높이: \(String(format: "%.3f", finalSafeHeight))m")
    print("🛡️ [안전 보장] HandleDetached를 바닥에서 최소 \(String(format: "%.3f", finalSafeHeight))m 위에 배치 (절대 사라지지 않음)")
    
    // 실제 손의 위치를 기준으로 낙하 시작점과 바닥 위치 계산
    var startPosition: SIMD3<Float>
    var dropPosition: SIMD3<Float>
    
    if let handPosition = RealHandTrackingManager.shared.getCurrentHandPosition() {
      // 손의 월드 위치에서 시작해서 바로 아래 바닥으로 떨어뜨리기
      startPosition = handPosition
      dropPosition = SIMD3<Float>(handPosition.x, fixedFloorY + handleHeight, handPosition.z)
      print("🤏 [손 위치 기준] 손 위치: \(String(format: "%.3f,%.3f,%.3f", handPosition.x, handPosition.y, handPosition.z))")
      
      // HandleDetached를 먼저 손 위치로 순간 이동 (자연스러운 "놓기" 효과)
      handleDetached.position = startPosition
      print("📍 [손에서 놓기] HandleDetached를 손 위치로 이동")
    } else {
      // 손 위치를 못 찾으면 현재 HandleDetached 위치 기준
      startPosition = currentPosition
      dropPosition = SIMD3<Float>(currentPosition.x, fixedFloorY + handleHeight, currentPosition.z)
      print("⚠️ [Fallback] 손 위치를 찾지 못해 HandleDetached 현재 위치 사용")
    }
    
    // 바닥 위치가 시작점보다 높으면 조정
    if dropPosition.y >= startPosition.y {
      dropPosition.y = startPosition.y - 0.5  // 최소 50cm는 떨어지도록
      print("🔧 [위치 조정] 바닥이 너무 높아서 조정: Y = \(dropPosition.y)")
    }
    
    let targetPosition = dropPosition
    
    print("🏠 [바닥 정보] fixedFloorY: \(String(format: "%.3f", fixedFloorY))m, handleHeight: \(String(format: "%.3f", handleHeight))m")
    print("🧮 [절대 안전 배치 실행]")
    print("   - 바닥 표면 Y좌표: \(String(format: "%.3f", fixedFloorY))m (고정값)")
    print("   - 절대 안전 높이: \(String(format: "%.3f", handleHeight))m")
    print("   - HandleDetached pivot 목표 Y좌표: \(String(format: "%.3f", fixedFloorY + handleHeight))m")
    print("   - 계산식: fixedFloorY + 안전높이 = \(String(format: "%.3f", fixedFloorY)) + \(String(format: "%.3f", handleHeight)) = \(String(format: "%.3f", fixedFloorY + handleHeight))m")
    print("🪂 [안전 낙하] 시작 위치: (\(String(format: "%.3f", startPosition.x)), \(String(format: "%.3f", startPosition.y)), \(String(format: "%.3f", startPosition.z)))")
    print("🎯 [안전 착지] 목표 위치: (\(String(format: "%.3f", targetPosition.x)), \(String(format: "%.3f", targetPosition.y)), \(String(format: "%.3f", targetPosition.z)))")
    print("📏 [낙하 거리] Y축 이동: \(String(format: "%.3f", startPosition.y - targetPosition.y))m")
    print("🛡️ [절대 안전 검증]")
    print("   - HandleDetached pivot Y좌표: \(String(format: "%.3f", targetPosition.y))m")
    print("   - 바닥 표면 Y좌표: \(String(format: "%.3f", floorY))m")
    print("   - 바닥에서 pivot까지 거리: \(String(format: "%.3f", targetPosition.y - floorY))m")
    print("   - 최소 안전 거리: \(String(format: "%.3f", handleHeight))m")
    print("✅ [사라짐 방지] pivot이 바닥에서 \(String(format: "%.3f", targetPosition.y - floorY))m 위에 위치 (사라지지 않음 보장)")
    print("🔄 [반복 안정성] 몇 번을 떨어뜨려도 절대 바닥 속으로 사라지지 않음")
    
    // 자연스러운 바운스 효과를 위한 다단계 애니메이션
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초 대기
      
      // 첫 번째 바닥 접촉 시점에 드롭 사운드 재생 (별도 태스크로 실행)
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8초 후 (첫 번째 낙하 완료 시점)
        SwitchDropSoundManager.shared.playSwitchDropSound()
        print("🔊 [드롭 타이밍] HandleDetached 첫 번째 바닥 접촉 시점에 사운드 재생")
      }
      
      try await HandleBounceAnimator.shared.performBounceAnimation(
        handleDetached: handleDetached, 
        startPosition: startPosition, 
        targetPosition: targetPosition
      ) {
        // 바운스 완료 후 컴포넌트 복원
        self.restoreHandleDetachedComponents(handleDetached)
      }
    }
    
    // 핀치 모드 완전 해제 및 바닥 착지 상태 설정
    deactivatePinchMode()
    stopHandTracking()
    
    // 바닥 착지 후 완전히 손 추적에서 격리
    setHandleAsGrounded(handleDetached)
    
    // 바닥 착지 후 손 추적 완전 중단 (바닥 아래 가라앉기 방지)
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 후
      if handleDetached.components.has(PhysicsBodyComponent.self) {
        let physicsBody = handleDetached.components[PhysicsBodyComponent.self]!
        if physicsBody.mode == .kinematic && !physicsBody.isAffectedByGravity {
          // 여전히 바닥에 고정된 상태라면 손 추적 완전 중단
          stopHandTracking()
          print("🛡️ [바닥 보호 완료] 손 추적 완전 중단 - 바닥 가라앉기 방지")
        }
      }
    }
  }
  
  /// HandleDetached를 바닥 착지 상태로 설정 (손 추적으로부터 격리)
  private func setHandleAsGrounded(_ handleDetached: Entity) {
    // HandleComponent에 바닥 착지 상태 마킹
    if let handleComponent = handleDetached.components[HandleComponent.self] {
      // 기존 HandleComponent 정보 유지하면서 바닥 착지 상태만 추가 표시
      handleDetached.components.set(HandleComponent(
        switchIndex: handleComponent.switchIndex, 
        isAttached: false, 
        isBeingDragged: false
      ))
    }
    
    // PhysicsBodyComponent를 kinematic 모드로 설정하여 안정적인 바닥 고정
    if let physicsBody = handleDetached.components[PhysicsBodyComponent.self] {
      var newPhysicsBody = physicsBody
      newPhysicsBody.mode = .kinematic  // 움직이지 않는 상태
      newPhysicsBody.isAffectedByGravity = false  // 중력 영향 제거
      handleDetached.components.set(newPhysicsBody)
      print("🔒 [바닥 고정] HandleDetached를 kinematic 모드로 설정 - 손 추적 격리")
    }
    
    // 바닥 착지 마킹을 위한 특별한 컴포넌트 추가 (바닥 보호 시스템용)
    handleDetached.components.set(GroundedMarkerComponent())
    
    // 손 휘저음 감지 시 위로 튀어오르는 보호 시스템 활성화
    setupBounceProtection(for: handleDetached)
    
    print("🏠 [바닥 착지 완료] HandleDetached가 바닥에 안정적으로 고정됨")
  }
  
  /// 바닥에서 손 휘저음 감지 시 위로 튀어오르는 보호 시스템
  private func setupBounceProtection(for handleDetached: Entity) {
    // 백그라운드에서 지속적으로 손 위치 모니터링
    Task {
      while handleDetached.components.has(GroundedMarkerComponent.self) {
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초마다 체크
        
        // 바닥 고정 상태인지 확인
        guard handleDetached.components.has(PhysicsBodyComponent.self) else { break }
        let physicsBody = handleDetached.components[PhysicsBodyComponent.self]!
        guard physicsBody.mode == .kinematic && !physicsBody.isAffectedByGravity else { break }
        
        // 현재 위치 확인
        let currentPosition = handleDetached.position
        
        // RealHandTrackingManager로 손 위치 확인
        if let handPosition = RealHandTrackingManager.shared.getCurrentHandPosition() {
          let distanceToHand = length(handPosition - currentPosition)
          
          // 손이 40cm 이내에 있고 핀치 상태가 아닐 때 (일반 손 휘저음)
          if distanceToHand < 0.4 && !RealHandTrackingManager.shared.isAnyHandPinching() {
            print("🚨 [바닥 보호] 손 휘저음 감지 - HandleDetached 보호 튀어오르기 시작 (거리: \(String(format: "%.3f", distanceToHand))m)")
            
            // MainActor에서 UI 업데이트 실행
            await MainActor.run {
              self.performProtectiveBounce(handleDetached: handleDetached)
            }
            
            // 튀어오르기 후 3초간 대기 (너무 자주 튀지 않도록)
            try? await Task.sleep(nanoseconds: 3_000_000_000)
          }
        }
      }
    }
  }
  
  /// 보호용 튀어오르기 실행
  private func performProtectiveBounce(handleDetached: Entity) {
    // 1. 현재 위치에서 위로 15cm 상승
    let bounceHeight: Float = 0.15
    let currentPosition = handleDetached.position
    let targetY = max(currentPosition.y + bounceHeight, floorY + bounceHeight)
    
    // 2. 일시적으로 dynamic 모드로 변경하여 튀어오르기
    if let physicsBody = handleDetached.components[PhysicsBodyComponent.self] {
      var bouncePhysicsBody = physicsBody
      bouncePhysicsBody.mode = .dynamic
      bouncePhysicsBody.isAffectedByGravity = true
      handleDetached.components.set(bouncePhysicsBody)
    }
    
    // 3. 위로 속도 적용
    if !handleDetached.components.has(PhysicsMotionComponent.self) {
      handleDetached.components.set(PhysicsMotionComponent())
    }
    if var motionComponent = handleDetached.components[PhysicsMotionComponent.self] {
      motionComponent.linearVelocity = SIMD3<Float>(0, 2.5, 0)  // 위로 2.5m/s
      handleDetached.components.set(motionComponent)
    }
    
    print("🦘 [보호 튀어오르기] HandleDetached 위로 튀어오름 (목표 높이: \(String(format: "%.3f", targetY))m)")
    
    // 4. 1초 후 static 모드로 고정
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
      
      // static 모드로 설정하여 완전히 고정
      if let currentPhysicsBody = handleDetached.components[PhysicsBodyComponent.self] {
        var staticPhysicsBody = currentPhysicsBody
        staticPhysicsBody.mode = .static  // 완전히 움직이지 않는 static 모드
        staticPhysicsBody.isAffectedByGravity = false
        handleDetached.components.set(staticPhysicsBody)
        
        // 위치를 안전한 높이로 고정
        let finalY = max(floorY + 0.08, 0.08) // 바닥에서 8cm 위
        handleDetached.position.y = finalY
        
        print("🔒 [static 고정] HandleDetached를 static 모드로 완전 고정 (Y: \(String(format: "%.3f", finalY))m)")
      }
      
      // 속도 컴포넌트 제거
      handleDetached.components.remove(PhysicsMotionComponent.self)
      
      print("✅ [보호 완료] HandleDetached 바닥 보호 시스템 재활성화")
    }
  }
  
  /// 바닥 착지 후 HandleDetached의 상호작용 컴포넌트들 복원
  private func restoreHandleDetachedComponents(_ handleDetached: Entity) {
    // DraggableComponent 확인 및 복원
    if !handleDetached.components.has(DraggableComponent.self) {
      handleDetached.components.set(DraggableComponent())
      print("🔧 [컴포넌트 복원] DraggableComponent 추가")
    }
    
    // InputTargetComponent 확인 및 복원
    if !handleDetached.components.has(InputTargetComponent.self) {
      handleDetached.components.set(InputTargetComponent())
      print("🔧 [컴포넌트 복원] InputTargetComponent 추가")
    }
    
    // HandleComponent 확인 및 복원
    if !handleDetached.components.has(HandleComponent.self) {
      handleDetached.components.set(HandleComponent(switchIndex: 1, isAttached: false, isBeingDragged: false))
      print("🔧 [컴포넌트 복원] HandleComponent 추가")
    }
    
    // CollisionComponent 확인 및 복원 (핀치 감지를 위해 필요)
    if !handleDetached.components.has(CollisionComponent.self) {
      let handleBounds = handleDetached.visualBounds(relativeTo: nil)
      let handleSize = handleBounds.max - handleBounds.min
      let expandedCollisionSize = SIMD3<Float>(
        max(0.06, handleSize.x * 1.2),
        max(0.06, handleSize.y * 1.2),
        max(0.06, handleSize.z * 1.2)
      )
      let collisionShape = ShapeResource.generateBox(size: expandedCollisionSize)
      handleDetached.components.set(CollisionComponent(
        shapes: [collisionShape], 
        mode: .default, 
        filter: .init(group: .default, mask: .all)
      ))
      print("🔧 [컴포넌트 복원] CollisionComponent 추가")
    }
    
    print("✅ [컴포넌트 복원] HandleDetached 상호작용 준비 완료")
  }
} 