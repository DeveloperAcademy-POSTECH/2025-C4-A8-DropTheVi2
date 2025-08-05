//
//  SwitchDragGesture+HandleDetached.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit

// MARK: - HandleDetached 처리 로직
extension SwitchDragGesture {
  
  /// HandleDetached를 월드 좌표계에서 직접 처리하는 메인 함수
  func handleDetachedDragInWorld(_ value: EntityTargetValue<DragGesture.Value>, _ entity: Entity) {
    guard let anchor = viewModel.getAnchor() else { return }
    
    // 현재 제스처
    let currentTranslation = value.translation
    let deltaTranslation = CGSize(
      width: currentTranslation.width - lastGestureTranslation.width,
      height: currentTranslation.height - lastGestureTranslation.height
    )
    
    let handTrackingManager = HandTrackingManager.shared
    let realHandTrackingManager = RealHandTrackingManager.shared
    
    // HandleDetached가 바닥에 고정된 상태인지 확인
    var isHandleOnFloor = false
    if entity.components.has(PhysicsBodyComponent.self) {
      let physicsBody = entity.components[PhysicsBodyComponent.self]!
      isHandleOnFloor = (physicsBody.mode == .kinematic && !physicsBody.isAffectedByGravity)
    }
    
    // 실제 핀치 상태 확인 (바닥에 있을 때는 더 관대한 감지)
    let isCurrentlyPinching = if isHandleOnFloor {
      realHandTrackingManager.isAnyHandPinchingForFloorPickup()  // 더 관대한 핀치 감지
    } else {
      realHandTrackingManager.isAnyHandPinching()  // 일반 핀치 감지
    }
    
    // 핀치 상태 변화 감지 및 핀치 모드 전환
    handlePinchStateChanges(
      isCurrentlyPinching: isCurrentlyPinching,
      handTrackingManager: handTrackingManager,
      realHandTrackingManager: realHandTrackingManager,
      entity: entity
    )
    
    // 핀치 모드인 경우 실제 손 위치로 업데이트
    if handTrackingManager.isPinchModeActive {
      handlePinchModeUpdate(
        isCurrentlyPinching: isCurrentlyPinching,
        handTrackingManager: handTrackingManager,
        realHandTrackingManager: realHandTrackingManager,
        entity: entity
      )
    } else {
      // 일반 손 추적 모드 - 바닥 고정 상태에서는 실행하지 않음
      if !isHandleOnFloor {
        handTrackingManager.updateHandMovement(deltaTranslation: deltaTranslation, handleDetached: entity)
      } else {
        print("🛡️ [바닥 보호] HandleDetached가 바닥에 고정된 상태 - 일반 손 추적 차단")
        // 바닥에 고정된 상태에서 손이 닿으면 살짝 튀어오르게 함
        applyGroundBounceEffect(to: entity)
      }
    }
    
    // lastGestureTranslation 업데이트
    lastGestureTranslation = currentTranslation
    
    // 엔티티 설정 및 물리 컴포넌트 관리
    setupEntityForDrag(entity: entity, anchor: anchor)
  }
  
  /// 핀치 상태 변화 처리
  private func handlePinchStateChanges(
    isCurrentlyPinching: Bool,
    handTrackingManager: HandTrackingManager,
    realHandTrackingManager: RealHandTrackingManager,
    entity: Entity
  ) {
    if isCurrentlyPinching && !handTrackingManager.isPinchModeActive {
      // 핀치 모드 시작 - 유예 시간 리셋
      pinchReleaseTime = nil
      
      let realHandPosition = realHandTrackingManager.getCurrentHandPosition()
      let cameraPosition = viewModel.currentCameraPosition
      let cameraForward = viewModel.currentCameraForward
      
      let targetPosition: SIMD3<Float>
      if let handPos = realHandPosition, realHandTrackingManager.handTrackingActiveStatus {
        targetPosition = handPos
        print("🤏 [실제 핀치 시작] 손 위치: \(String(format: "%.3f,%.3f,%.3f", handPos.x, handPos.y, handPos.z))")
      } else {
        targetPosition = cameraPosition + normalize(cameraForward) * 0.5
        print("🤏 [핀치 시작 - 추정] 카메라 앞 50cm")
      }
      
      // 핀치 모드 시작 시 누적 이동량 초기화
      accumulatedPinchMovement = .zero
      
      handTrackingManager.activatePinchMode(
        handWorldPosition: targetPosition,
        cameraForward: cameraForward,
        handleDetached: entity
      )
      
      print("🖐️ [핸드 트래킹] 상태: \(realHandTrackingManager.handTrackingActiveStatus ? "✅활성" : "❌비활성")")
    } else if !isCurrentlyPinching && handTrackingManager.isPinchModeActive {
      // 핀치가 해제되면 유예 시간 시작 (즉시 떨어뜨리지 않음)
      handlePinchRelease(handTrackingManager: handTrackingManager, entity: entity)
    }
  }
  
  /// 핀치 해제 처리
  private func handlePinchRelease(handTrackingManager: HandTrackingManager, entity: Entity) {
    if pinchReleaseTime == nil {
      pinchReleaseTime = Date()
      print("🤏 [핀치 해제 감지] \(pinchReleaseGracePeriod)초 유예 시간 시작 (다시 핀치하면 계속 잡기 가능)")
    } else {
      // 이미 유예 시간이 시작된 상태에서 다시 핀치 해제 감지
      let elapsedTime = Date().timeIntervalSince(pinchReleaseTime!)
      if elapsedTime >= pinchReleaseGracePeriod {
        // 유예 시간 만료: HandleDetached를 바닥으로 떨어뜨리기
        print("⏰ [유예 시간 만료] \(String(format: "%.1f", elapsedTime))초 경과 - HandleDetached 떨어뜨리기")
        handTrackingManager.dropToFloor(handleDetached: entity)
        isDraggingHandle = false
        draggedHandle = nil
        return
      } else {
        print("⏳ [유예 중] \(String(format: "%.1f", pinchReleaseGracePeriod - elapsedTime))초 남음")
      }
    }
  }
  
  /// 핀치 모드 업데이트 처리
  private func handlePinchModeUpdate(
    isCurrentlyPinching: Bool,
    handTrackingManager: HandTrackingManager,
    realHandTrackingManager: RealHandTrackingManager,
    entity: Entity
  ) {
    if isCurrentlyPinching {
      // 핀치 중일 때는 유예 시간 리셋 (연속 핀치 허용)
      pinchReleaseTime = nil
      
      // 핀치 모드 중에는 실제 손 위치로 실시간 업데이트
      let realHandPosition = realHandTrackingManager.getCurrentHandPosition()
      let cameraPosition = viewModel.currentCameraPosition
      let cameraForward = viewModel.currentCameraForward
      
      let targetPosition: SIMD3<Float>
      if let handPos = realHandPosition, realHandTrackingManager.handTrackingActiveStatus {
        targetPosition = handPos
      } else {
        targetPosition = cameraPosition + normalize(cameraForward) * 0.5
      }
      
      handTrackingManager.updatePinchModeHandPosition(
        handWorldPosition: targetPosition,
        cameraForward: cameraForward
      )
      
      // Switch1과의 거리 확인 및 Handle 복원 체크
      if handTrackingManager.checkSwitchProximityAndRestore(handleDetached: entity) {
        print("🔄 [거리 체크] HandleDetached가 Switch1에 복원되었습니다")
        return // Handle이 복원되면 더 이상 처리하지 않음
      }
    }
  }
  
  /// 엔티티 드래그 설정 및 물리 컴포넌트 관리
  private func setupEntityForDrag(entity: Entity, anchor: Entity) {
    // 엔티티 설정 (드래그 중 상태)
    if entity.parent != anchor {
      entity.removeFromParent()
      anchor.addChild(entity)
    }
    
    // HandleDetached가 바닥에 고정된 상태인지 확인
    var isFloorFixed = false
    if entity.components.has(PhysicsBodyComponent.self) {
      let physicsBody = entity.components[PhysicsBodyComponent.self]!
      isFloorFixed = (physicsBody.mode == .kinematic && !physicsBody.isAffectedByGravity)
    }
    
    // 바닥에 고정된 상태가 아닐 때만 물리 컴포넌트 제거 (바닥 뚫림 방지)
    if !isFloorFixed {
      entity.components.remove(PhysicsBodyComponent.self)
      entity.components.remove(CollisionComponent.self)
      print("🔧 [물리 컴포넌트] 드래그 중 제거 (일반 상태)")
    } else {
      print("🛡️ [물리 컴포넌트] 바닥 고정 상태이므로 제거하지 않음 (바닥 뚫림 방지)")
    }
    
    // HandleComponent 상태 업데이트
    if var handleComponent = entity.components[HandleComponent.self] {
      let newHandleComponent = HandleComponent(
        switchIndex: handleComponent.switchIndex,
        isAttached: false,
        isBeingDragged: true
      )
      entity.components.set(newHandleComponent)
    }
  }
}