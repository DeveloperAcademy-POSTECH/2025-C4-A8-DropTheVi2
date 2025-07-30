//
//  HandTrackingManager.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit

@MainActor
@Observable
final class HandTrackingManager {
  static let shared = HandTrackingManager()
  private init() {}
  
  // 손 움직임 추적 상태
  private var isTracking = false
  private var initialHandlePosition: SIMD3<Float> = .zero
  private var lastHandGesture: CGSize = .zero
  private var accumulatedMovement: SIMD3<Float> = .zero
  
  // 핀치 모드 상태
  private var isPinchMode = false
  private var targetHandPosition: SIMD3<Float> = .zero  // 손의 목표 위치
  private var smoothingSpeed: Float = 8.0  // 부드러운 이동 속도
  private let pinchDistance: Float = 0.2  // 손에서 HandleDetached까지의 거리 (20cm)
  private var pinchBasePosition: SIMD3<Float> = .zero  // 핀치 시작 기준 위치
  
  // 감도 설정
  private let sensitivity: Float = 0.003  // 손 움직임 감도 (0.005 → 0.003으로 감소)
  private let maxMovementRange: Float = 5.0  // 최대 이동 거리 (1.5 → 5.0미터로 확대)
  private let pinchModeMaxRange: Float = 10.0  // 핀치 모드에서는 더 큰 범위 허용
  private var floorY: Float = 0.0  // 바닥 Y 좌표 (동적으로 업데이트됨)
  private let switchAttachDistance: Float = 0.30  // Switch에 부착되는 거리 (30cm로 확대)
  
  /// 손 추적 시작
  func startHandTracking(for handleDetached: Entity) {
    guard !isTracking else { return }
    
    isTracking = true
    initialHandlePosition = handleDetached.position
    lastHandGesture = .zero
    accumulatedMovement = .zero
    
    // 바닥 위치 업데이트
    updateFloorPosition()
    
    print("🖐️ [손 추적 시작] HandleDetached 위치: \(initialHandlePosition)")
    print("📐 [감도 설정] \(sensitivity), 최대 범위: ±\(maxMovementRange)m")
    print("🏠 [바닥 위치] Y좌표: \(floorY)")
  }
  
  /// 손 움직임 업데이트
  func updateHandMovement(deltaTranslation: CGSize, handleDetached: Entity) {
    guard isTracking else { 
      print("⚠️ [손 추적] 추적이 비활성화 상태입니다")
      return 
    }
    
    // HandleDetached가 kinematic 모드(바닥 착지 후 고정 상태)인지 확인
    if handleDetached.components.has(PhysicsBodyComponent.self) {
      let physicsBody = handleDetached.components[PhysicsBodyComponent.self]!
      if physicsBody.mode == .kinematic && !physicsBody.isAffectedByGravity {
        // 바닥에 착지하여 고정된 상태 - 손 움직임에 반응하지 않음
        print("🛡️ [손 추적 차단] HandleDetached가 바닥에 고정된 상태 - 손 움직임 무시")
        return
      }
    }
    
    // 핀치 모드 우선 처리
    if isPinchMode {
      updatePinchMode(handleDetached: handleDetached)
      return  // 핀치 모드 중에는 일반 손 추적 무시
    }
    
    // 핀치나 극도로 큰 움직임 감지 (안전장치)
    let deltaWidth = Float(deltaTranslation.width)
    let deltaHeight = Float(deltaTranslation.height)
    let totalDelta = sqrt(deltaWidth * deltaWidth + deltaHeight * deltaHeight)
    
    // 극도로 큰 움직임 차단 (핀치 제스처나 오류 상황)
    if totalDelta > 100.0 {
      print("🚨 [핀치 감지] 극도로 큰 움직임 감지 (\(String(format: "%.1f", totalDelta))) - 핀치나 오류로 판단하여 무시")
      return
    }
    
    // 손 움직임 변화량 계산
    let handDeltaX = deltaWidth * sensitivity
    let handDeltaY = -deltaHeight * sensitivity  // Y축 반전
    
    // 누적 움직임 업데이트
    accumulatedMovement.x += handDeltaX
    accumulatedMovement.y += handDeltaY
    
    // 범위 제한 완화 (Switch1까지 도달 가능하도록)
    accumulatedMovement.x = max(-maxMovementRange, min(maxMovementRange, accumulatedMovement.x))
    accumulatedMovement.y = max(-maxMovementRange, min(maxMovementRange, accumulatedMovement.y))
    
    // 새로운 위치 계산
    let newPosition = initialHandlePosition + accumulatedMovement
    
    // 위치 유효성 검증 - 더 큰 범위 허용 (Switch1 도달 가능)
    let worldDistance = length(newPosition)
    if worldDistance > 15.0 {  // 10.0 → 15.0미터로 확대
      print("🚨 [위치 제한] HandleDetached가 너무 멀리 이동하려 함 (\(String(format: "%.1f", worldDistance))m) - 이동 차단")
      return
    }
    
    // Switch1 방향 이동 특별 허용 (Switch1은 대략 (-1.97, 0.17, 0.77) 근처)
    let switch1Position = SIMD3<Float>(-1.97, 0.17, 0.77)
    let distanceToSwitch1 = length(newPosition - switch1Position)
    if distanceToSwitch1 < 2.0 {  // Switch1 주변 2미터는 항상 허용
      print("✅ [Switch1 근접] Switch1 방향 이동 허용 - 거리: \(String(format: "%.3f", distanceToSwitch1))m")
    }
    
    // HandleDetached 위치 업데이트
    handleDetached.position = newPosition
    
    // 로그 출력 (변화가 있을 때만)
    if abs(handDeltaX) > 0.001 || abs(handDeltaY) > 0.001 {
      print("🖐️ [손 추적 이동] 델타: (\(String(format: "%.3f", handDeltaX)), \(String(format: "%.3f", handDeltaY))) 원시입력: (\(String(format: "%.1f,%.1f", deltaWidth, deltaHeight)))")
      print("📍 [누적 이동] 총: (\(String(format: "%.3f", accumulatedMovement.x)), \(String(format: "%.3f", accumulatedMovement.y)))")
      print("🎯 [최종 위치] \(String(format: "%.3f,%.3f,%.3f", newPosition.x, newPosition.y, newPosition.z))")
    }
  }
  
  /// 손 추적 종료
  func stopHandTracking() {
    guard isTracking else { return }
    
    isTracking = false
    isPinchMode = false  // 핀치 모드도 함께 종료
    print("🖐️ [손 추적 종료] 최종 누적 이동: \(accumulatedMovement)")
    
    // 상태 초기화
    initialHandlePosition = .zero
    lastHandGesture = .zero
    accumulatedMovement = .zero
    targetHandPosition = .zero
    pinchBasePosition = .zero  // 핀치 기준 위치 초기화
  }
  
  /// 현재 추적 상태 확인
  var isHandTracking: Bool {
    return isTracking
  }
  
  /// 초기 위치 반환 (드래그 종료 시 원래 위치 복귀용)
  var getInitialPosition: SIMD3<Float> {
    // 손 추적이 시작되지 않았거나 초기 위치가 설정되지 않은 경우 안전한 기본값 반환
    if !isTracking || initialHandlePosition == .zero {
      print("⚠️ [손 추적] 초기 위치가 설정되지 않음 - 기본 HandleDetached 위치 사용")
      return SIMD3<Float>(-1.0375092, 0.6638181, 1.1334089)  // 로그에서 확인된 실제 위치
    }
    return initialHandlePosition
  }
  
  /// 감도 조정
  func adjustSensitivity(_ newSensitivity: Float) {
    let clampedSensitivity = max(0.001, min(0.01, newSensitivity))
    print("🔧 [감도 조정] \(sensitivity) → \(clampedSensitivity)")
  }
  
  /// 위치 리셋 (원점으로 복귀)
  func resetPosition(for handleDetached: Entity) {
    handleDetached.position = initialHandlePosition
    accumulatedMovement = .zero
    isPinchMode = false
    targetHandPosition = .zero
    pinchBasePosition = .zero
    print("🔄 [위치 리셋] HandleDetached를 초기 위치로 복귀: \(initialHandlePosition)")
  }
  
  // MARK: - 핀치 모드 제어
  
  /// 핀치 모드 활성화 (HandleDetached를 지정된 위치로 부름)
  func activatePinchMode(handWorldPosition: SIMD3<Float>, cameraForward: SIMD3<Float>, handleDetached: Entity) {
    guard isTracking else {
      print("⚠️ [핀치 모드] 손 추적이 비활성화 상태 - 핀치 모드 활성화 불가")
      return
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
    
    // HandleDetached가 kinematic 모드(바닥 착지 후 고정 상태)인지 확인
    if handleDetached.components.has(PhysicsBodyComponent.self) {
      let physicsBody = handleDetached.components[PhysicsBodyComponent.self]!
      if physicsBody.mode == .kinematic && !physicsBody.isAffectedByGravity {
        // 바닥에 착지하여 고정된 상태 - 손 움직임에 반응하지 않음
        print("🛡️ [핀치 모드 차단] HandleDetached가 바닥에 고정된 상태 - 손 움직임 무시")
        return
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
  
  /// 거리 체크 후 Handle1 복원 (실제 핀치아웃 후에만 실행)
  func checkSwitchProximityAndRestore(handleDetached: Entity) -> Bool {
    // 핀치 모드 중에는 자동 부착 안함 (핀치아웃 이후에만 실행)
    if isPinchMode {
      print("❌ [핀치 모드 비활성] 일반 손 추적 모드")
      return false  // 핀치 모드 중에는 부착하지 않음
    }
    
    let handleManager = HandleManager.shared
    if handleManager.checkHandleDetachedProximityToSwitch1(from: RoomViewModel.shared.rootEntity) {
      print("✅ [연결 성공] HandleDetached → Handle1 교체 시작")
      handleManager.restoreHandle1ToSwitch1()
      
      // Handle1이 생성되었으므로 손 추적 중단
      stopHandTracking()
      print("🔄 [손 추적 중단] Handle1 생성 완료로 인한 자동 중단")
      
      return true
    }
    
    return false
  }
  
  /// Switch1 엔티티 찾기
  private func findSwitch1Entity() -> Entity? {
    let roomViewModel = RoomViewModel.shared
    let rootEntity = roomViewModel.rootEntity
    
    let entitySearchManager = EntitySearchManager.shared
    if let roomEntity = entitySearchManager.findRoomEntity(from: rootEntity) {
      return entitySearchManager.findSwitchEntity(in: roomEntity, switchNumber: 1)
    }
    
    return nil
  }
  
  /// Handle1을 Switch1에 복원하고 HandleDetached 숨기기
  private func restoreHandle1ToSwitch1() {
    print("🔄 [Handle 복원] Switch1에 Handle1 복원 시작")
    
    // HandleManager를 통해 Handle 복원
    let handleManager = HandleManager.shared
    handleManager.restoreHandle1ToSwitch1()
    
    // 핀치 모드 종료
    deactivatePinchMode()
    stopHandTracking()
    
    print("✅ [Handle 복원] Switch1 Handle1이 활성화되었습니다")
  }
  
  /// 바닥 위치 업데이트 (정확한 표면 위치 계산)
  private func updateFloorPosition() {
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
    let currentPosition = handleDetached.position
    
    // 바닥 위치를 고정된 안전한 값으로 설정 (매번 재계산하지 않음)
    // 이를 통해 HandleDetached가 점점 더 아래로 떨어지는 문제 해결
    let fixedFloorY: Float = 0.0  // 고정된 바닥 높이
    
    // 확실한 안전을 위해 절대적으로 안전한 높이 사용
    // 바닥 계산에 의존하지 않고 충분히 높은 위치에 배치
    
    // HandleDetached의 현재 상태 확인
    let handleCurrentWorldPos = handleDetached.convert(position: SIMD3<Float>(0, 0, 0), to: nil)
    let handleLocalBounds = handleDetached.visualBounds(relativeTo: handleDetached)
    let handleWorldBounds = handleDetached.visualBounds(relativeTo: nil)
    
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
    
    // 핀치 모드 완전 해제
    deactivatePinchMode()
    stopHandTracking()
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

  
  // MARK: - Public Properties
  
  /// Switch 연결 거리 임계값
  var switchAttachDistanceThreshold: Float {
    return switchAttachDistance
  }
} 
