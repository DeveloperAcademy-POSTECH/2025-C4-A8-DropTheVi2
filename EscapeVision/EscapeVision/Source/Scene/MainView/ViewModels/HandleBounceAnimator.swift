import Foundation
import RealityKit
import simd

/// HandleDetached의 바운스 애니메이션을 담당하는 클래스
class HandleBounceAnimator {
  
  static let shared = HandleBounceAnimator()
  
  private init() {}
  
  /// 자연스러운 바운스 효과를 가진 바닥 떨어뜨리기 애니메이션
  @MainActor
  func performBounceAnimation(handleDetached: Entity, startPosition: SIMD3<Float>, targetPosition: SIMD3<Float>, onComplete: (() -> Void)? = nil) async throws {
    let fallHeight = startPosition.y - targetPosition.y
    
    print("🎬 [바운스 애니메이션] 시작 - 총 낙하 높이: \(String(format: "%.3f", fallHeight))m")
    
    // 핸들이 바닥에 평평하게 눕도록 하는 최종 회전 계산
    let startRotation = handleDetached.orientation
    let finalRotation = calculateFlatRotation(from: startRotation, entity: handleDetached)
    
    print("🔄 [회전 정보] 시작: \(startRotation), 최종: \(finalRotation)")
    
    // 1단계: 첫 번째 낙하 (빠른 속도 + 회전)
    let fallDuration: TimeInterval = 0.8  // 회전을 더 명확히 보기 위해 시간 증가
    let fallAnimation = FromToByAnimation<Transform>(
      name: "initialFall",
      from: .init(scale: .one, rotation: startRotation, translation: startPosition),
      to: .init(scale: .one, rotation: finalRotation, translation: targetPosition),
      duration: fallDuration,
      timing: .easeIn,
      bindTarget: .transform
    )
    
    if let animationResource = try? AnimationResource.generate(with: fallAnimation) {
      handleDetached.playAnimation(animationResource)
      print("🪂 [1단계] 첫 번째 낙하 시작 - \(fallDuration)초")
      try await Task.sleep(nanoseconds: UInt64(fallDuration * 1_000_000_000))
    }
    
    // 2단계: 첫 번째 바운스 (높게)
    let bounce1Height = fallHeight * 0.25  // 원래 높이의 25%
    let bounce1Position = SIMD3<Float>(targetPosition.x, targetPosition.y + bounce1Height, targetPosition.z)
    try await performSingleBounce(handleDetached: handleDetached, 
                                   fromPosition: targetPosition, 
                                   toPosition: bounce1Position, 
                                   rotation: finalRotation,
                                   duration: 0.2, 
                                   bounceNumber: 1)
    
    // 3단계: 두 번째 바운스 (중간)
    let bounce2Height = fallHeight * 0.10  // 원래 높이의 10%
    let bounce2Position = SIMD3<Float>(targetPosition.x, targetPosition.y + bounce2Height, targetPosition.z)
    try await performSingleBounce(handleDetached: handleDetached, 
                                   fromPosition: bounce1Position, 
                                   toPosition: bounce2Position, 
                                   rotation: finalRotation,
                                   duration: 0.15, 
                                   bounceNumber: 2)
    
    // 4단계: 세 번째 바운스 (낮게)
    let bounce3Height = fallHeight * 0.03  // 원래 높이의 3%
    let bounce3Position = SIMD3<Float>(targetPosition.x, targetPosition.y + bounce3Height, targetPosition.z)
    try await performSingleBounce(handleDetached: handleDetached, 
                                   fromPosition: bounce2Position, 
                                   toPosition: bounce3Position, 
                                   rotation: finalRotation,
                                   duration: 0.1, 
                                   bounceNumber: 3)
    
    // 5단계: 최종 정착
    let settleAnimation = FromToByAnimation<Transform>(
      name: "finalSettle",
      from: .init(scale: .one, rotation: finalRotation, translation: bounce3Position),
      to: .init(scale: .one, rotation: finalRotation, translation: targetPosition),
      duration: 0.1,
      timing: .easeOut,
      bindTarget: .transform
    )
    
    if let animationResource = try? AnimationResource.generate(with: settleAnimation) {
      handleDetached.playAnimation(animationResource)
      print("🎯 [최종단계] 바닥 정착 시작")
      try await Task.sleep(nanoseconds: 100_000_000)
    }
    
    // 최종 위치 강제 고정 및 안전 보장
    print("🎯 [절대 안전 착지] targetPosition: (\(String(format: "%.3f", targetPosition.x)), \(String(format: "%.3f", targetPosition.y)), \(String(format: "%.3f", targetPosition.z)))")
    
    // 1단계: 위치 설정
    handleDetached.position = targetPosition
    handleDetached.orientation = finalRotation
    
    // 2단계: 물리 설정을 즉시 고정하여 더 이상 떨어지지 않도록
    if handleDetached.components.has(PhysicsBodyComponent.self) {
      var physicsBody = handleDetached.components[PhysicsBodyComponent.self]!
      physicsBody.mode = .kinematic  // kinematic으로 고정
      physicsBody.isAffectedByGravity = false  // 중력 영향 제거
      handleDetached.components.set(physicsBody)
    }
    
    // 3단계: 위치 재확인 및 강제 고정
    handleDetached.position = targetPosition  // 다시 한 번 확실히 설정
    
    print("✅ [위치 강제 고정] handleDetached.position: (\(String(format: "%.3f", handleDetached.position.x)), \(String(format: "%.3f", handleDetached.position.y)), \(String(format: "%.3f", handleDetached.position.z)))")
    print("🛡️ [물리 안전화] kinematic 모드 + 중력 비활성화로 더 이상 떨어지지 않음")
    print("🎯 [절대 안전 착지 완료] HandleDetached가 절대 사라지지 않는 위치에 고정됨 (다시 드래그 가능)")
    
    // 완료 콜백 실행 (컴포넌트 복원 등을 위임)
    onComplete?()
    

    
    print("🏁 [바운스 완료] HandleDetached가 바닥에 완전히 정착했습니다: Y = \(targetPosition.y)")
  }
  

  
  /// 핸들이 바닥에 평평하게 눕도록 하는 회전 계산 (넓은 면이 바닥으로 가도록)
  private func calculateFlatRotation(from currentRotation: simd_quatf, entity: Entity) -> simd_quatf {
    // HandleDetached의 실제 크기 분석
    let handleBounds = entity.visualBounds(relativeTo: entity)
    let handleSize = handleBounds.max - handleBounds.min
    
    print("📏 [크기 분석] HandleDetached 크기: X=\(String(format: "%.3f", handleSize.x)), Y=\(String(format: "%.3f", handleSize.y)), Z=\(String(format: "%.3f", handleSize.z))")
    
    // 각 면의 넓이 계산
    let xyArea = handleSize.x * handleSize.y  // XY 면 (앞뒤면)
    let xzArea = handleSize.x * handleSize.z  // XZ 면 (윗아래면)
    let yzArea = handleSize.y * handleSize.z  // YZ 면 (좌우면)
    
    print("📐 [면적 분석] XY면=\(String(format: "%.4f", xyArea)), XZ면=\(String(format: "%.4f", xzArea)), YZ면=\(String(format: "%.4f", yzArea))")
    
    // 가장 넓은 면 찾기
    let maxArea = max(xyArea, xzArea, yzArea)
    
    var finalRotation: simd_quatf
    
    if maxArea == xzArea {
      // XZ 면이 가장 넓음 - 이미 바닥과 평행하므로 Y축 회전만 조정
      print("🔄 [회전 선택] XZ면이 가장 넓음 - 그대로 바닥에 평평하게 배치")
      
      // 현재 회전을 회전 행렬로 변환하여 Y축 회전만 유지
      let rotMatrix = matrix_float3x3(currentRotation)
      let forwardXZ = normalize(SIMD3<Float>(rotMatrix.columns.2.x, 0, rotMatrix.columns.2.z))
      
      let rightVector = normalize(cross(SIMD3<Float>(0, 1, 0), forwardXZ))
      let upVector = SIMD3<Float>(0, 1, 0)
      let correctedForward = cross(rightVector, upVector)
      
      let flatMatrix = matrix_float3x3(
        rightVector,       // X축
        upVector,          // Y축 (위쪽)
        correctedForward   // Z축
      )
      
      finalRotation = simd_quatf(flatMatrix)
      
         } else if maxArea == xyArea {
       // XY 면이 가장 넓음 - XY면을 바닥과 평행하게 회전
       print("🔄 [회전 선택] XY면이 가장 넓음 - XY면을 바닥으로 향하도록 회전")
       
       // XY면이 바닥(XZ 평면)과 평행하게 하려면 X축 주위로 90도 회전 필요
       // 현재 회전을 고려해서 자연스러운 방향으로 회전
       let currentMatrix = matrix_float3x3(currentRotation)
       let currentUp = currentMatrix.columns.1  // 현재 Y축 방향
       
       // Y축이 XZ 평면을 향하도록 X축 주위로 회전
       let targetMatrix = matrix_float3x3(
         SIMD3<Float>(1, 0, 0),  // X축 유지
         SIMD3<Float>(0, 0, 1),  // Y축 → Z축 방향 (XY면이 수평)
         SIMD3<Float>(0, 1, 0)   // Z축 → Y축 방향
       )
       
       finalRotation = simd_quatf(targetMatrix)
       
     } else {
       // YZ 면이 가장 넓음 - YZ면을 바닥과 평행하게 회전
       print("🔄 [회전 선택] YZ면이 가장 넓음 - YZ면을 바닥으로 향하도록 회전")
       
       // YZ면이 바닥(XZ 평면)과 평행하게 하려면 Z축 주위로 90도 회전 필요
       // 현재 회전을 고려해서 자연스러운 방향으로 회전
       let currentMatrix = matrix_float3x3(currentRotation)
       let currentRight = currentMatrix.columns.0  // 현재 X축 방향
       
       // X축이 Y축 방향으로 가도록 Z축 주위로 회전
       let targetMatrix = matrix_float3x3(
         SIMD3<Float>(0, 1, 0),  // X축 → Y축 방향 (YZ면이 수평)
         SIMD3<Float>(1, 0, 0),  // Y축 → X축 방향  
         SIMD3<Float>(0, 0, 1)   // Z축 유지
       )
       
       finalRotation = simd_quatf(targetMatrix)
     }
    
    print("🔄 [회전 완료] 넓은 면(면적=\(String(format: "%.4f", maxArea)))이 바닥으로 향하도록 회전 적용")
    
    return finalRotation
  }
  
  /// 단일 바운스 애니메이션 수행 (올라갔다가 내려오기)
  @MainActor
  private func performSingleBounce(handleDetached: Entity, fromPosition: SIMD3<Float>, toPosition: SIMD3<Float>, rotation: simd_quatf, duration: TimeInterval, bounceNumber: Int) async throws {
    // 올라가기
    let upAnimation = FromToByAnimation<Transform>(
      name: "bounceUp\(bounceNumber)",
      from: .init(scale: .one, rotation: rotation, translation: fromPosition),
      to: .init(scale: .one, rotation: rotation, translation: toPosition),
      duration: duration / 2,
      timing: .easeOut,
      bindTarget: .transform
    )
    
    if let animationResource = try? AnimationResource.generate(with: upAnimation) {
      handleDetached.playAnimation(animationResource)
      print("⬆️ [바운스 \(bounceNumber)] 올라가기 - 높이: \(String(format: "%.3f", toPosition.y - fromPosition.y))m")
      try await Task.sleep(nanoseconds: UInt64((duration / 2) * 1_000_000_000))
    }
    
    // 내려오기
    let downAnimation = FromToByAnimation<Transform>(
      name: "bounceDown\(bounceNumber)",
      from: .init(scale: .one, rotation: rotation, translation: toPosition),
      to: .init(scale: .one, rotation: rotation, translation: fromPosition),
      duration: duration / 2,
      timing: .easeIn,
      bindTarget: .transform
    )
    
    if let animationResource = try? AnimationResource.generate(with: downAnimation) {
      handleDetached.playAnimation(animationResource)
      print("⬇️ [바운스 \(bounceNumber)] 내려오기")
      try await Task.sleep(nanoseconds: UInt64((duration / 2) * 1_000_000_000))
    }
  }
} 
