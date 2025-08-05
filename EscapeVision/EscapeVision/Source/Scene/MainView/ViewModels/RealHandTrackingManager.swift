//
//  RealHandTrackingManager.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit
import ARKit

@MainActor
@Observable
final class RealHandTrackingManager {
  static let shared = RealHandTrackingManager()
  private init() {}
  
  // 실제 손 위치 정보 (HandTrackingProvider에서 가져옴)
  var leftHandPosition: SIMD3<Float>? = nil
  var rightHandPosition: SIMD3<Float>? = nil
  var isLeftHandTracked: Bool = false
  var isRightHandTracked: Bool = false
  
  // HandAnchor 추적 (더 정확한 핀치 감지를 위해)
  private var currentLeftHandAnchor: HandAnchor? = nil
  private var currentRightHandAnchor: HandAnchor? = nil
  
  // 핀치 상태 정보 (HandSkeleton에서 계산)
  var isLeftHandPinching: Bool = false
  var isRightHandPinching: Bool = false
  private let pinchStartThreshold: Float = 0.08  // 8cm 이내면 핀치 시작 (더 민감한 감지)
  private let pinchEndThreshold: Float = 0.12   // 12cm 이상이면 핀치 해제 (히스테리시스)
  
  // ARKit HandTracking 관련
  private var handTrackingProvider: HandTrackingProvider?
  private var isHandTrackingActive: Bool = false
  
  /// HandTrackingProvider 설정
  func setHandTrackingProvider(_ provider: HandTrackingProvider) {
    self.handTrackingProvider = provider
  }
  
  /// HandTracking 활성화 상태 설정
  func setHandTrackingActive(_ active: Bool) {
    self.isHandTrackingActive = active
  }
  
  /// HandTracking 활성화 상태 확인
  var handTrackingActiveStatus: Bool {
    return isHandTrackingActive
  }
  
  /// 실제 손 위치 추적 시작 (HandTrackingProvider 사용)
  func startHandTracking() async {
    guard let handProvider = handTrackingProvider else {
      print("❌ [핸드 트래킹] HandTrackingProvider가 없음")
      return
    }
    
    print("🖐️ [핸드 트래킹] 실제 손 위치 추적 시작")
    
    for await update in handProvider.anchorUpdates {
      let handAnchor = update.anchor
      
      switch update.event {
      case .added, .updated:
        // 손이 추적되고 있는지 확인
        guard handAnchor.isTracked else { continue }
        await updateHandPositions(handAnchor)
        
      case .removed:
        // 손 추적이 끊어진 경우 해당 손의 정보 제거
        switch handAnchor.chirality {
        case .left:
          isLeftHandTracked = false
          leftHandPosition = nil
          isLeftHandPinching = false
          currentLeftHandAnchor = nil  // HandAnchor 참조 제거
          print("🖐️ [핸드 트래킹] 왼손 추적 종료")
          
        case .right:
          isRightHandTracked = false
          rightHandPosition = nil
          isRightHandPinching = false
          currentRightHandAnchor = nil  // HandAnchor 참조 제거
          print("🖐️ [핸드 트래킹] 오른손 추적 종료")
        }
      }
    }
  }
  
  /// 손 위치 업데이트
  private func updateHandPositions(_ handAnchor: HandAnchor) async {
    guard let handSkeleton = handAnchor.handSkeleton else {
      print("⚠️ [핸드 트래킹] \(handAnchor.chirality == .left ? "왼손" : "오른손") HandSkeleton이 없음")
      return
    }
    
    // 손목과 중지 끝을 사용해서 손 앞쪽 위치 계산
    let wristJoint = handSkeleton.joint(.wrist)
    let middleFingerTip = handSkeleton.joint(.middleFingerTip)
    
    let wristTransform = handAnchor.originFromAnchorTransform * wristJoint.anchorFromJointTransform
    let tipTransform = handAnchor.originFromAnchorTransform * middleFingerTip.anchorFromJointTransform
    
    let wristPosition = SIMD3<Float>(wristTransform.columns.3.x, wristTransform.columns.3.y, wristTransform.columns.3.z)
    let tipPosition = SIMD3<Float>(tipTransform.columns.3.x, tipTransform.columns.3.y, tipTransform.columns.3.z)
    
    // 손목에서 손가락 끝 방향으로 벡터 계산 후 손 앞쪽으로 조금 더 이동
    let handDirection = normalize(tipPosition - wristPosition)
    let handFrontOffset: Float = 0.08  // 8cm 앞쪽
    let adjustedHandPosition = wristPosition + handDirection * handFrontOffset
    
    switch handAnchor.chirality {
    case .left:
      leftHandPosition = adjustedHandPosition
      isLeftHandTracked = true
      currentLeftHandAnchor = handAnchor  // HandAnchor 저장
      
    case .right:
      rightHandPosition = adjustedHandPosition
      isRightHandTracked = true
      currentRightHandAnchor = handAnchor  // HandAnchor 저장
    }
    
    // 핀치 상태 감지 (엄지와 검지 손가락 끝의 거리 계산)
    detectPinchState(handAnchor: handAnchor, handSkeleton: handSkeleton)
    
    // 손 위치 로그 (주기적으로)
    struct HandLog {
      static var lastLogTime: Date = Date()
    }
    
    let currentTime = Date()
    if currentTime.timeIntervalSince(HandLog.lastLogTime) > 2.0 {  // 2초마다
      let leftPosStr = leftHandPosition.map { String(format: "%.3f,%.3f,%.3f", $0.x, $0.y, $0.z) } ?? "없음"
      let rightPosStr = rightHandPosition.map { String(format: "%.3f,%.3f,%.3f", $0.x, $0.y, $0.z) } ?? "없음"
      print("🖐️ [실제 손 위치] 왼손: \(isLeftHandTracked ? "✅" : "❌") \(leftPosStr), 오른손: \(isRightHandTracked ? "✅" : "❌") \(rightPosStr)")
      HandLog.lastLogTime = currentTime
    }
  }
  
  /// 현재 추적 중인 손의 위치 반환 (핀치용)
  func getCurrentHandPosition() -> SIMD3<Float>? {
    // 오른손 우선, 없으면 왼손
    if let rightPos = rightHandPosition, isRightHandTracked {
      return rightPos
    } else if let leftPos = leftHandPosition, isLeftHandTracked {
      return leftPos
    }
    return nil
  }
  
  /// 현재 핀치 상태 확인
  func isAnyHandPinching() -> Bool {
    return isLeftHandPinching || isRightHandPinching
  }
  
  /// 바닥에서 집기용 더 관대한 핀치 감지 (임계값 50% 증가)
  func isAnyHandPinchingForFloorPickup() -> Bool {
    // 바닥에 있는 객체를 집기 위해 더 큰 임계값 사용
    let floorPickupStartThreshold = pinchStartThreshold * 1.5  // 8cm → 12cm
    let floorPickupEndThreshold = pinchEndThreshold * 1.5    // 12cm → 18cm
    
    // 왼손 체크
    let leftHandFloorPinching = checkFloorPickupPinch(
      isCurrentlyPinching: isLeftHandPinching,
      handAnchor: getLeftHandAnchor(),
      startThreshold: floorPickupStartThreshold,
      endThreshold: floorPickupEndThreshold
    )
    
    // 오른손 체크  
    let rightHandFloorPinching = checkFloorPickupPinch(
      isCurrentlyPinching: isRightHandPinching,
      handAnchor: getRightHandAnchor(), 
      startThreshold: floorPickupStartThreshold,
      endThreshold: floorPickupEndThreshold
    )
    
    return leftHandFloorPinching || rightHandFloorPinching
  }
  
  /// 바닥 집기용 핀치 상태 체크 (더 관대한 임계값 사용)
  private func checkFloorPickupPinch(
    isCurrentlyPinching: Bool,
    handAnchor: HandAnchor?,
    startThreshold: Float,
    endThreshold: Float
  ) -> Bool {
    guard let handAnchor = handAnchor,
          let handSkeleton = handAnchor.handSkeleton else {
      return false
    }
    
    // 엄지 끝과 검지 끝 위치 가져오기
    let thumbTip = handSkeleton.joint(.thumbTip)
    let indexTip = handSkeleton.joint(.indexFingerTip)
    
    // 월드 좌표계에서의 위치 계산
    let thumbTransform = handAnchor.originFromAnchorTransform * thumbTip.anchorFromJointTransform
    let indexTransform = handAnchor.originFromAnchorTransform * indexTip.anchorFromJointTransform
    
    let thumbPosition = SIMD3<Float>(thumbTransform.columns.3.x, thumbTransform.columns.3.y, thumbTransform.columns.3.z)
    let indexPosition = SIMD3<Float>(indexTransform.columns.3.x, indexTransform.columns.3.y, indexTransform.columns.3.z)
    
    // 두 손가락 끝 사이의 거리 계산
    let distance = length(thumbPosition - indexPosition)
    
    // 히스테리시스를 사용한 핀치 감지 (바닥 집기용 더 관대한 임계값)
    let isPinching: Bool
    if isCurrentlyPinching {
      // 이미 핀치 상태인 경우, 더 큰 거리에서 해제
      isPinching = distance < endThreshold
    } else {
      // 핀치하지 않은 상태인 경우, 더 큰 거리에서 시작 (바닥 집기용)
      isPinching = distance < startThreshold
    }
    
    return isPinching
  }
  
  /// 왼손 HandAnchor 가져오기 (내부 추적용)
  private func getLeftHandAnchor() -> HandAnchor? {
    return currentLeftHandAnchor
  }
  
  /// 오른손 HandAnchor 가져오기 (내부 추적용) 
  private func getRightHandAnchor() -> HandAnchor? {
    return currentRightHandAnchor
  }
  
  /// 핀치 상태 감지 (엄지와 검지 손가락 끝의 거리 계산)
  private func detectPinchState(handAnchor: HandAnchor, handSkeleton: HandSkeleton) {
    // 엄지 끝과 검지 끝 위치 가져오기
    let thumbTip = handSkeleton.joint(.thumbTip)
    let indexTip = handSkeleton.joint(.indexFingerTip)
    
    // 월드 좌표계에서의 위치 계산
    let thumbTransform = handAnchor.originFromAnchorTransform * thumbTip.anchorFromJointTransform
    let indexTransform = handAnchor.originFromAnchorTransform * indexTip.anchorFromJointTransform
    
    let thumbPosition = SIMD3<Float>(thumbTransform.columns.3.x, thumbTransform.columns.3.y, thumbTransform.columns.3.z)
    let indexPosition = SIMD3<Float>(indexTransform.columns.3.x, indexTransform.columns.3.y, indexTransform.columns.3.z)
    
    // 두 손가락 끝 사이의 거리 계산
    let distance = length(thumbPosition - indexPosition)
    
    // 히스테리시스를 사용한 핀치 감지 (이전 상태에 따라 다른 임계값 사용)
    let previousPinchState = handAnchor.chirality == .left ? isLeftHandPinching : isRightHandPinching
    let isPinching: Bool
    
    if previousPinchState {
      // 이미 핀치 상태인 경우, 더 큰 거리에서 해제
      isPinching = distance < pinchEndThreshold
    } else {
      // 핀치하지 않은 상태인 경우, 더 작은 거리에서 시작
      isPinching = distance < pinchStartThreshold
    }
    
    switch handAnchor.chirality {
    case .left:
      isLeftHandPinching = isPinching
      if previousPinchState != isPinching {
        let threshold = previousPinchState ? pinchEndThreshold : pinchStartThreshold
        print("🤏 [실제 핀치 감지] 왼손: \(isPinching ? "✅핀치 시작" : "❌핀치 해제") 거리: \(String(format: "%.3f", distance))m (임계값: \(String(format: "%.3f", threshold))m)")
      }
      
    case .right:
      isRightHandPinching = isPinching
      if previousPinchState != isPinching {
        let threshold = previousPinchState ? pinchEndThreshold : pinchStartThreshold
        print("🤏 [실제 핀치 감지] 오른손: \(isPinching ? "✅핀치 시작" : "❌핀치 해제") 거리: \(String(format: "%.3f", distance))m (임계값: \(String(format: "%.3f", threshold))m)")
      }
    }
  }
} 