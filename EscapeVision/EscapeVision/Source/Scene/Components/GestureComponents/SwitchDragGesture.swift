//
//  SwitchDragGesture.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit

/// HandleDetached 새로운 직관적 제어 시스템
/// - 핀치: 손에서 10cm 앞 위치에 객체 배치
/// - 상하 이동: 핸드 제스처 직접 반영
/// - 앞뒤 이동: 핸드 제스처 (손을 몸쪽으로 당기면 가까이, 밀면 멀리)
/// - 좌우 이동: 주로 Vision Pro 머리 회전, 핸드 제스처는 미세 조정
struct SwitchDragGesture: Gesture {
  let viewModel: RoomViewModel
  @State private var isDraggingHandle = false
  @State private var draggedHandle: Entity?
  @State private var isDetachedHandle = false
  
  // Switch Handle 전용
  @State private var originalHandlePosition: SIMD3<Float>?
  @State private var originalHandleOrientation: simd_quatf?
  
  // 제스처 추적용 공통 상태 (HandleDetached 및 일반 스위치 핸들 모두 사용)
  @State private var lastGestureTranslation: CGSize = .zero  // 이전 제스처 (델타 계산용)
  @State private var accumulatedPinchMovement: SIMD3<Float> = .zero  // 핀치 모드 누적 이동
  
  // 핀치 해제 지연 관련 (바닥에서 줍기 편의성 향상)
  @State private var pinchReleaseTime: Date?
  private let pinchReleaseGracePeriod: TimeInterval = 1.5  // 1.5초 유예 시간
  
  // 바닥 튀어오름 효과 쿨다운 관련
  @State private var lastBounceTime: Date?
  private let bounceCooldown: TimeInterval = 2.0  // 2초 쿨다운
  
  var body: some Gesture {
    DragGesture()
      .targetedToAnyEntity()
      .onChanged { value in
        handleDragChanged(value)
      }
      .onEnded { value in
        handleDragEnded(value)
      }
  }
  
  private func handleDragChanged(_ value: EntityTargetValue<DragGesture.Value>) {
    // 드래그 가능한 엔티티 찾기
    guard let draggableEntity = value.entity.findDraggableParent() else { 
      return 
    }
    
    // HandleDetached에 필요한 컴포넌트 자동 설정
    if draggableEntity.name.contains("Sphere_005") && draggableEntity.components[HandleComponent.self] == nil {
      draggableEntity.components.set(HandleComponent(switchIndex: 1, isAttached: false, isBeingDragged: false))
    }
    
    // 첫 드래그 시작
    if !isDraggingHandle {
      isDraggingHandle = true
      draggedHandle = draggableEntity
      
      // 🎯 거리 체크: ARKit 카메라 위치 기준 계산
      let entityWorldPos = draggableEntity.convert(position: .zero, to: nil)
        _ = viewModel.currentCameraTransform
      let cameraPos = viewModel.currentCameraPosition
      let distance = length(entityWorldPos - cameraPos)
      
      print("🎯 [거리 체크] 엔티티: \(entityWorldPos), 카메라: \(cameraPos), 거리: \(String(format: "%.2f", distance))m")
      
      // Vision Pro 환경에서는 3미터까지 허용 (팔 길이 + 여유)
      if distance > 3.0 {
        print("❌ [거리 제한] \(String(format: "%.2f", distance))m - 3m 이내에서만 집기 가능")
        isDraggingHandle = false
        draggedHandle = nil
        return
      }
      
      print("✅ [거리 확인] \(String(format: "%.2f", distance))m")
      
      // HandleDetached인지 확인
      if let handleComponent = draggableEntity.components[HandleComponent.self] {
        isDetachedHandle = !handleComponent.isAttached
        
        if isDetachedHandle {
          // HandleDetached가 바닥에 고정된 상태인지 확인
          var isHandleGrounded = false
          if draggableEntity.components.has(PhysicsBodyComponent.self) {
            let physicsBody = draggableEntity.components[PhysicsBodyComponent.self]!
            isHandleGrounded = (physicsBody.mode == .kinematic && !physicsBody.isAffectedByGravity)
          }
          
          // 바닥에 고정된 상태라면 실제 핀치 의도가 있는지 확인
          if isHandleGrounded {
            let realHandTrackingManager = RealHandTrackingManager.shared
            let isActuallyPinching = realHandTrackingManager.isAnyHandPinchingForFloorPickup()
            
            if isActuallyPinching {
              // 실제 핀치 의도가 있을 때만 바닥 고정 해제
              var newPhysicsBody = draggableEntity.components[PhysicsBodyComponent.self]!
              newPhysicsBody.mode = .dynamic
              newPhysicsBody.isAffectedByGravity = true
              draggableEntity.components.set(newPhysicsBody)
              print("🔓 [핀치 의도 감지] 실제 핀치로 바닥 고정 해제")
            } else {
              // 핀치 의도가 없으면 바닥 고정 상태 유지하면서 살짝 튀어오르게 함
              print("🛡️ [바닥 보호] 핀치 의도 없음 - 바닥에서 살짝 튀어오름")
              applyGroundBounceEffect(to: draggableEntity)
              isDraggingHandle = false
              draggedHandle = nil
              return
            }
          }
          
          // 손 추적 시스템 시작
          let handTrackingManager = HandTrackingManager.shared
          handTrackingManager.startHandTracking(for: draggableEntity)
          
          // 시스템 초기화
          lastGestureTranslation = .zero
          accumulatedPinchMovement = .zero  // 핀치 누적 이동량 초기화
          
          print("🖐️ [HandleDetached 드래그 시작] 손 추적 시스템으로 제어 시작")
        } else {
          // Switch handle: 원래 위치 저장
          originalHandlePosition = draggableEntity.position
          originalHandleOrientation = draggableEntity.orientation
        }
      } else if findSwitchParent(for: draggableEntity) != nil {
        // 기존 스위치 핸들
        isDetachedHandle = false
        originalHandlePosition = draggableEntity.position
        originalHandleOrientation = draggableEntity.orientation
      }
      return
    }
    
    // 드래그 중 처리
    if isDetachedHandle {
      // HandleDetached: 월드 좌표계에서 직접 처리
      handleDetachedDragInWorld(value, draggableEntity)
      
      // 새 시스템에서는 별도 상태 체크 불필요
    } else {
      // Switch handle: 핀치 제스처 감지 및 처리
      handleNormalSwitchPinchGesture(value, draggableEntity)
      
      // 위치 고정 (스위치 핸들은 물리적으로 이동하지 않음)
      if let originalPos = originalHandlePosition,
         let originalOrient = originalHandleOrientation {
        draggableEntity.position = originalPos
        draggableEntity.orientation = originalOrient
      }
    }
  }
  
  private func handleDragEnded(_ value: EntityTargetValue<DragGesture.Value>) {
    guard isDraggingHandle, let draggedEntity = draggedHandle else { return }
    
    if isDetachedHandle {
      // HandleDetached: 핀치 해제 처리
      let handTrackingManager = HandTrackingManager.shared
      
      // 핀치가 해제되면 유예 시간 시작
      if handTrackingManager.isPinchModeActive {
        pinchReleaseTime = Date()
        print("🤏 [드래그 종료] 핀치 해제 - \(pinchReleaseGracePeriod)초 유예 시간 시작")
      } else {
        // 핀치 모드가 아닌 상태에서 드래그 종료 (일반 손 추적)
        print("🖐️ [드래그 종료] 일반 손 추적 상태에서 종료")
        handTrackingManager.stopHandTracking()
      }
    } else {
      // 일반 스위치 핸들: 원래 위치로 복원
      if let originalPos = originalHandlePosition,
         let originalOrient = originalHandleOrientation {
        draggedEntity.position = originalPos
        draggedEntity.orientation = originalOrient
      }
      
      // HandleComponent 업데이트
      if var handleComponent = draggedEntity.components[HandleComponent.self] {
        let newHandleComponent = HandleComponent(
          switchIndex: handleComponent.switchIndex,
          isAttached: handleComponent.isAttached,
          isBeingDragged: false
        )
        draggedEntity.components.set(newHandleComponent)
      }
    }
    
    // 상태 초기화
    isDraggingHandle = false
    draggedHandle = nil
    originalHandlePosition = nil
    originalHandleOrientation = nil
    lastGestureTranslation = .zero
    accumulatedPinchMovement = .zero
  }
  
  private func handleNormalSwitchPinchGesture(_ value: EntityTargetValue<DragGesture.Value>, _ entity: Entity) {
    // 일반 스위치 핸들 핀치 처리 로직
    // (기존 로직 유지)
  }
  
  private func findSwitchParent(for entity: Entity) -> Entity? {
    // 스위치 부모 찾기 로직
    // (기존 로직 유지)
    return nil
  }
}