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
  
  // 손 움직임 추적 상태 (extensions에서 접근하기 위해 internal)
  var isTracking = false
  private var initialHandlePosition: SIMD3<Float> = .zero
  private var lastHandGesture: CGSize = .zero
  private var accumulatedMovement: SIMD3<Float> = .zero
  
  // 핀치 모드 상태 (extensions에서 접근하기 위해 internal)
  var isPinchMode = false
  var targetHandPosition: SIMD3<Float> = .zero  // 손의 목표 위치
  var smoothingSpeed: Float = 8.0  // 부드러운 이동 속도
  private let pinchDistance: Float = 0.2  // 손에서 HandleDetached까지의 거리 (20cm)
  var pinchBasePosition: SIMD3<Float> = .zero  // 핀치 시작 기준 위치
  var pinchModeActivationTime: Date?  // 핀치 모드 활성화 시간 (바닥 감지 유예용)
  
  // 감도 설정
  private let sensitivity: Float = 0.003  // 손 움직임 감도 (0.005 → 0.003으로 감소)
  private let maxMovementRange: Float = 5.0  // 최대 이동 거리 (1.5 → 5.0미터로 확대)
  let pinchModeMaxRange: Float = 10.0  // 핀치 모드에서는 더 큰 범위 허용
  var floorY: Float = 0.0  // 바닥 Y 좌표 (동적으로 업데이트됨, extensions에서 접근)
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
    let handDeltaY = deltaHeight * sensitivity  // Y축 방향 수정: 손을 위로 올리면 객체도 위로
    
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
      let deltaStr = "(\(String(format: "%.3f", handDeltaX)), \(String(format: "%.3f", handDeltaY)))"
      let rawInputStr = "(\(String(format: "%.1f,%.1f", deltaWidth, deltaHeight)))"
      print("🖐️ [손 추적 이동] 델타: \(deltaStr) 원시입력: \(rawInputStr)")
      
      let accX = String(format: "%.3f", accumulatedMovement.x)
      let accY = String(format: "%.3f", accumulatedMovement.y)
      print("📍 [누적 이동] 총: (\(accX), \(accY))")
      
      let posX = String(format: "%.3f", newPosition.x)
      let posY = String(format: "%.3f", newPosition.y)
      let posZ = String(format: "%.3f", newPosition.z)
      let positionStr = "(\(posX), \(posY), \(posZ))"
      print("🎯 [최종 위치] \(positionStr)")
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
    pinchModeActivationTime = nil  // 핀치 활성화 시간 초기화
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
  
  // MARK: - Public Properties
  
  /// Switch 연결 거리 임계값
  var switchAttachDistanceThreshold: Float {
    return switchAttachDistance
  }
} 
