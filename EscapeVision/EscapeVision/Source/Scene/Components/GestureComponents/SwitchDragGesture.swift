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
  
  private func handleDetachedDragInWorld(_ value: EntityTargetValue<DragGesture.Value>, _ entity: Entity) {
    guard let anchor = viewModel.getAnchor() else { return }
    
    // 현재 제스처
    let currentTranslation = value.translation
    let deltaTranslation = CGSize(
      width: currentTranslation.width - lastGestureTranslation.width,
      height: currentTranslation.height - lastGestureTranslation.height
    )
    
    let handTrackingManager = HandTrackingManager.shared
    let realHandTrackingManager = RealHandTrackingManager.shared
    
    // 실제 핀치 상태 확인 및 핀치 모드 활성화/비활성화
    let isCurrentlyPinching = realHandTrackingManager.isAnyHandPinching()
    
    // 핀치 상태 변화 감지 및 핀치 모드 전환
    if isCurrentlyPinching && !handTrackingManager.isPinchModeActive {
      // 핀치 모드 시작
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
      // 핀치가 해제되면 바닥으로 떨어뜨리기
      print("🤏 [핀치 해제] HandleDetached를 바닥으로 떨어뜨립니다")
      handTrackingManager.dropToFloor(handleDetached: entity)
      accumulatedPinchMovement = .zero
    }
    
    // 핀치 모드인 경우 실제 손 위치로 업데이트
    if handTrackingManager.isPinchModeActive {
      if isCurrentlyPinching {
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
    } else {
      // 일반 손 추적 모드
      handTrackingManager.updateHandMovement(deltaTranslation: deltaTranslation, handleDetached: entity)
    }
    
    // lastGestureTranslation 업데이트
    lastGestureTranslation = currentTranslation
    
    // 엔티티 설정 (드래그 중 상태)
    if entity.parent != anchor {
      entity.removeFromParent()
      anchor.addChild(entity)
    }
    
    entity.components.remove(PhysicsBodyComponent.self)
    entity.components.remove(CollisionComponent.self)
    
    // 손 추적 상태 확인용 로그 (큰 변화가 있을 때만)
    if abs(Float(deltaTranslation.width)) > 10 || abs(Float(deltaTranslation.height)) > 10 {
      let handTrackingManager = HandTrackingManager.shared
      print("📱 [SwitchDragGesture] 큰 입력: (\(String(format: "%.1f,%.1f", deltaTranslation.width, deltaTranslation.height))) 손추적상태: \(handTrackingManager.isHandTracking ? "✅" : "❌")")
    }
    
    lastGestureTranslation = currentTranslation
  }
  
  private func handleDragEnded(_ value: EntityTargetValue<DragGesture.Value>) {
    defer {
      isDraggingHandle = false
      draggedHandle = nil
      isDetachedHandle = false
      originalHandlePosition = nil
      originalHandleOrientation = nil
      // 손 추적 시스템 변수 초기화
      lastGestureTranslation = .zero
      accumulatedPinchMovement = .zero  // 핀치 누적 이동량 초기화
    }
    
    guard let draggableEntity = value.entity.findDraggableParent() else { return }
    
    if isDetachedHandle {
      // 손 추적 종료
      let handTrackingManager = HandTrackingManager.shared
      handTrackingManager.stopHandTracking()
      
      // HandleDetached 드래그 종료
      endHandleDetachedDrag(draggableEntity)
    } else {
      // 일반 스위치 핸들 (Switch1~5) 토글 처리
      handleNormalSwitchToggle(draggableEntity, value)
    }
  }
  
  func endHandleDetachedDrag(_ entity: Entity) {
    guard let anchor = viewModel.getAnchor() else { return }
    
    // 드래그 상태 해제
    if var handleComponent = entity.components[HandleComponent.self] {
      handleComponent.isBeingDragged = false
      entity.components.set(handleComponent)
    }
    
    // Switch1 근접 체크 - 연결되면 여기서 종료
    let handleManager = HandleManager.shared
    if handleManager.checkHandleDetachedProximityToSwitch1(from: viewModel.rootEntity) {
      handleManager.attachHandleDetachedToSwitch1(from: viewModel.rootEntity)
      print("🎯 [HandleDetached 종료] Switch1에 연결됨")
      return
    }
    
    // 연결되지 않으면 바닥에 떨어뜨림
    let handTrackingManager = HandTrackingManager.shared
    handTrackingManager.dropToFloor(handleDetached: entity)
    
    print("🎯 [HandleDetached 종료] 바닥으로 떨어뜨림")
  }
  
  func findSwitchParent(for entity: Entity) -> Entity? {
    // 먼저 일반적인 부모 검색으로 실제 Switch 찾기
    var currentEntity: Entity? = entity
    while let current = currentEntity {
      if let switchComponent = current.components[SwitchComponent.self] {
        let switchIndex = switchComponent.switchIndex
        print("🎯 [Switch 감지] \(current.name)의 Handle1 → Switch\(switchIndex) 토글")
        return current
      }
      currentEntity = current.parent
    }
    
    // 부모 검색으로 못 찾았을 때만 특별 처리 (HandleDetached → Switch1 전용)
    if entity.name == "HandleDetached" {
      print("🎯 [특별 처리] HandleDetached 감지 - Switch1 강제 반환")
      
      // Switch1을 직접 찾아서 반환
      if let roomEntity = findRoomEntity(from: entity),
         let switch1 = EntitySearchManager.shared.findSwitchEntity(in: roomEntity, switchNumber: 1) {
        
        // Switch1에 SwitchComponent가 없으면 추가
        if switch1.components[SwitchComponent.self] == nil {
          switch1.components.set(SwitchComponent(switchIndex: 1))
          print("🔧 [컴포넌트 추가] Switch1에 SwitchComponent 추가 (인덱스: 1)")
        }
        
        print("✅ [특별 처리] HandleDetached → Switch1 반환 성공")
        return switch1
      } else {
        print("❌ [특별 처리] Switch1을 찾을 수 없음")
      }
    }
    
    print("❌ [Switch 찾기 실패] \(entity.name)의 부모 Switch를 찾을 수 없음")
    return nil
  }
  
  /// Room 엔티티 찾기 헬퍼 함수
  func findRoomEntity(from entity: Entity) -> Entity? {
    var currentEntity: Entity? = entity
    while let current = currentEntity {
      if current.name.lowercased().contains("room") {
        return current
      }
      currentEntity = current.parent
    }
    return nil
  }
  
  /// 일반 스위치 핸들 토글 처리 (Switch1~5)
  func handleNormalSwitchToggle(_ draggableEntity: Entity, _ value: EntityTargetValue<DragGesture.Value>) {
    print("🎮 [일반 스위치 토글] 드래그 종료 - 토글 처리 시작")
    
    // 스위치 부모 엔티티 찾기
    guard let switchParent = findSwitchParent(for: draggableEntity) else {
      print("❌ [토글 실패] 스위치 부모를 찾을 수 없음")
      return
    }
    
    // 드래그 방향 및 거리 계산
    let dragTranslation = value.translation
    let dragDistance = sqrt(dragTranslation.width * dragTranslation.width + dragTranslation.height * dragTranslation.height)
    let isUpwardDrag = dragTranslation.height > 0  // 화면에서 위로 드래그하면 height가 양수 (방향 수정)
    
    print("🔍 [드래그 방향 감지]")
    print("  - 드래그 거리: (\(String(format: "%.1f", dragTranslation.width)), \(String(format: "%.1f", dragTranslation.height)))")
    print("  - 총 드래그 거리: \(String(format: "%.1f", dragDistance))px")
    print("  - 감지된 방향: \(isUpwardDrag ? "위로" : "아래로")")
    print("  - Switch: \(switchParent.name)")
    print("  - Handle: \(draggableEntity.name)")
    
    // 최소 드래그 거리 확인 (의도하지 않은 토글 방지)
    let minimumDragDistance: CGFloat = 20.0  // 20픽셀 이상 드래그해야 토글
    
    if dragDistance < minimumDragDistance {
      print("⚠️ [토글 스킵] 드래그 거리가 너무 짧음 (\(String(format: "%.1f", dragDistance))px < \(minimumDragDistance)px)")
      return
    }
    
    // 스위치 토글 실행
    viewModel.toggleSwitchState(switchEntity: switchParent, handleEntity: draggableEntity, isUpward: isUpwardDrag)
    
    print("✅ [일반 스위치 토글] 토글 처리 완료")
  }
  
  /// 일반 스위치 핸들에 대한 핀치 제스처 처리
  private func handleNormalSwitchPinchGesture(_ value: EntityTargetValue<DragGesture.Value>, _ draggableEntity: Entity) {
    let realHandTrackingManager = RealHandTrackingManager.shared
    let isCurrentlyPinching = realHandTrackingManager.isAnyHandPinching()
    
    // 핀치 제스처가 감지된 경우에만 처리
    if isCurrentlyPinching {
      // 현재 제스처 위치와 이전 위치의 차이 계산
      let currentTranslation = value.translation
      let deltaTranslation = CGSize(
        width: currentTranslation.width - lastGestureTranslation.width,
        height: currentTranslation.height - lastGestureTranslation.height
      )
      
      // Y축 움직임이 충분한 경우에만 스위치 상태 변경
      let verticalThreshold: CGFloat = 15.0  // 15픽셀 이상 움직여야 반응
      
      if abs(deltaTranslation.height) > verticalThreshold {
        // 스위치 부모 엔티티 찾기
        guard let switchParent = findSwitchParent(for: draggableEntity) else {
          print("❌ [핀치 토글 실패] 스위치 부모를 찾을 수 없음")
          return
        }
        
        // 핀치 제스처 방향 결정 (손을 위로 올리면 스위치 올리기)
        let isUpwardPinch = deltaTranslation.height < 0  // 화면 좌표계에서 위로 움직이면 음수
        
        print("🤏 [핀치 스위치 토글] 핀치 제스처 감지")
        print("  - 제스처 델타: (\(String(format: "%.1f", deltaTranslation.width)), \(String(format: "%.1f", deltaTranslation.height)))")
        print("  - 감지된 방향: \(isUpwardPinch ? "위로" : "아래로")")
        print("  - Switch: \(switchParent.name)")
        print("  - Handle: \(draggableEntity.name)")
        
        // 스위치 토글 실행
        viewModel.toggleSwitchState(switchEntity: switchParent, handleEntity: draggableEntity, isUpward: isUpwardPinch)
        
        // 중복 토글 방지를 위해 이전 제스처 위치 업데이트
        lastGestureTranslation = currentTranslation
        
        print("✅ [핀치 스위치 토글] 핀치 토글 처리 완료")
      }
    }
    
    // 일반 드래그 제스처용 이전 위치 업데이트
    lastGestureTranslation = value.translation
  }
}
