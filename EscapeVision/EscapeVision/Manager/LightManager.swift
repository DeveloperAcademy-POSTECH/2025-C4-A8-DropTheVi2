//
//  LightManager.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/29/25.
//

import Foundation
import SwiftUI
import RealityKit

final class LightManager {
  static let shared = LightManager()
  
  private init() {}
  
  // MARK: - Properties
  private var whiteOutLight: Entity?
  private var currentTimer: Timer?
  
  // MARK: - Public Methods
  
  /// WhiteOut 효과용 PointLight 조명을 설정
  /// - Parameter content: RealityViewContent
  func setupWhiteOutLight(in content: RealityViewContent) {
    let lightEntity = Entity()
    lightEntity.name = "whiteOutLight"
    
    // PointLight 컴포넌트 생성
    var light = PointLightComponent()
    light.color = .white
    light.intensity = 100
    light.attenuationRadius = 500.0 // 조명이 영향을 미치는 범위
    
    lightEntity.components.set(light)
    
    // PointLight는 사용자 근처 중앙 위쪽에 배치 (모든 방향으로 빛 발산)
    lightEntity.position = SIMD3<Float>(0, 1, 0)
    
    content.add(lightEntity)
    whiteOutLight = lightEntity
    
    print("🔆 LightManager: WhiteOut PointLight 조명 설정 완료")
  }
  
  /// WhiteOut 효과용 PointLight를 커스텀 위치에 설정
  /// - Parameters:
  ///   - content: RealityViewContent
  ///   - position: PointLight 위치
  ///   - attenuationRadius: 조명 영향 범위
  func setupWhiteOutLight(in content: RealityViewContent,
                          position: SIMD3<Float> = SIMD3<Float>(0, 3, 0),
                          attenuationRadius: Float = 50.0) {
    let lightEntity = Entity()
    lightEntity.name = "whiteOutLight"
    
    var light = PointLightComponent()
    light.color = .white
    light.intensity = 100
    light.attenuationRadius = attenuationRadius
    
    lightEntity.components.set(light)
    lightEntity.position = position
    
    content.add(lightEntity)
    whiteOutLight = lightEntity
    
    print("🔆 LightManager: WhiteOut PointLight 설정 완료 - 위치: \(position), 범위: \(attenuationRadius)")
  }
  
  /// WhiteOut 효과 시작
  /// - Parameters:
  ///   - onCompletion: 효과 완료 후 실행할 클로저
  func startWhiteOutEffect(onCompletion: (() -> Void)? = nil) {
    guard let lightEntity = whiteOutLight else {
      print("❌ LightManager: WhiteOut 조명이 설정되지 않았습니다")
      return
    }
    
    print("🔆 LightManager: WhiteOut 효과 시작")
    
    // 기존 타이머가 있다면 정리
    currentTimer?.invalidate()
    
    // 10초 동안 intensity를 100에서 1000000까지 증가
    animateLightIntensity(
      entity: lightEntity,
      from: 100,
      to: 100000000,
      duration: 5.0,
      onCompletion: onCompletion
    )
  }
  
  /// 빠른 WhiteOut 효과 (3초)
  /// - Parameter onCompletion: 효과 완료 후 실행할 클로저
  func startQuickWhiteOutEffect(onCompletion: (() -> Void)? = nil) {
    guard let lightEntity = whiteOutLight else {
      print("❌ LightManager: WhiteOut 조명이 설정되지 않았습니다")
      return
    }
    
    print("🔆 LightManager: 빠른 WhiteOut 효과 시작 (3초)")
    
    currentTimer?.invalidate()
    
    animateLightIntensity(
      entity: lightEntity,
      from: 100,
      to: 500000,
      duration: 3.0,
      onCompletion: onCompletion
    )
  }
  
  /// 극적인 WhiteOut 효과 (느린 증가 후 급격한 증가)
  /// - Parameter onCompletion: 효과 완료 후 실행할 클로저
  func startDramaticWhiteOutEffect(onCompletion: (() -> Void)? = nil) {
    guard let lightEntity = whiteOutLight else {
      print("❌ LightManager: WhiteOut 조명이 설정되지 않았습니다")
      return
    }
    
    print("🔆 LightManager: 극적인 WhiteOut 효과 시작")
    
    currentTimer?.invalidate()
    
    // 첫 5초는 천천히, 마지막 2초는 급격히
    animateLightIntensityDramatic(
      entity: lightEntity,
      onCompletion: onCompletion
    )
  }
  
  /// WhiteOut 효과를 즉시 중단
  func stopWhiteOutEffect() {
    currentTimer?.invalidate()
    currentTimer = nil
    
    guard let lightEntity = whiteOutLight,
          var lightComponent = lightEntity.components[PointLightComponent.self] else {
      return
    }
    
    // intensity를 초기값으로 리셋
    lightComponent.intensity = 100
    lightEntity.components.set(lightComponent)
    
    print("🔆 LightManager: WhiteOut 효과 중단됨")
  }
  
  /// 조명을 제거
  func cleanup() {
    currentTimer?.invalidate()
    currentTimer = nil
    
    if let lightEntity = whiteOutLight {
      lightEntity.removeFromParent()
      whiteOutLight = nil
    }
    
    print("🔆 LightManager: 정리 완료")
  }
  
  // MARK: - Private Methods
  
  /// PointLight의 intensity를 애니메이션으로 변경
  /// - Parameters:
  ///   - entity: 조명 Entity
  ///   - startIntensity: 시작 intensity
  ///   - endIntensity: 종료 intensity
  ///   - duration: 애니메이션 지속시간
  ///   - onCompletion: 완료 후 실행할 클로저
  private func animateLightIntensity(
    entity: Entity,
    from startIntensity: Float,
    to endIntensity: Float,
    duration: TimeInterval,
    onCompletion: (() -> Void)? = nil
  ) {
    let startTime = Date()
    
    currentTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] timer in
      guard let self = self else {
        timer.invalidate()
        return
      }
      
      let elapsed = Date().timeIntervalSince(startTime)
      let progress = min(elapsed / duration, 1.0)
      
      // easeInOut 곡선 적용
      let easedProgress = self.easeInOut(Float(progress))
      let currentIntensity = startIntensity + (endIntensity - startIntensity) * easedProgress
      
      guard var lightComponent = entity.components[PointLightComponent.self] else {
        timer.invalidate()
        self.currentTimer = nil
        return
      }
      
      lightComponent.intensity = currentIntensity
      entity.components.set(lightComponent)
      
      if progress >= 1.0 {
        timer.invalidate()
        self.currentTimer = nil
        print("🔆 LightManager: WhiteOut 효과 완료!")
        onCompletion?()
      }
    }
    
    if let timer = currentTimer {
      RunLoop.current.add(timer, forMode: .common)
    }
  }
  
  /// 극적인 효과를 위한 특별한 애니메이션
  private func animateLightIntensityDramatic(
    entity: Entity,
    onCompletion: (() -> Void)? = nil
  ) {
    let startTime = Date()
    let totalDuration: TimeInterval = 5.0
    let slowPhase: TimeInterval = 3.0  // 처음 5초는 천천히
    let fastPhase: TimeInterval = 2.0  // 마지막 2초는 급격히
    
    currentTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] timer in
      guard let self = self else {
        timer.invalidate()
        return
      }
      
      let elapsed = Date().timeIntervalSince(startTime)
      let progress = min(elapsed / totalDuration, 1.0)
      
      var currentIntensity: Float
      
      if elapsed <= slowPhase {
        // 처음 3초: 100 → 50000 (천천히)
        let slowProgress = elapsed / slowPhase
        let easedSlowProgress = self.easeOut(Float(slowProgress))
        currentIntensity = 100 + (50000 - 100) * easedSlowProgress
      } else {
        // 마지막 2초: 50000 → 1000000 (급격히)
        let fastProgress = (elapsed - slowPhase) / fastPhase
        let easedFastProgress = self.easeIn(Float(fastProgress))
        currentIntensity = 50000 + (1000000 - 50000) * easedFastProgress
      }
      
      guard var lightComponent = entity.components[PointLightComponent.self] else {
        timer.invalidate()
        self.currentTimer = nil
        return
      }
      
      lightComponent.intensity = currentIntensity
      entity.components.set(lightComponent)
      
      if progress >= 1.0 {
        timer.invalidate()
        self.currentTimer = nil
        print("🔆 LightManager: 극적인 WhiteOut 효과 완료!")
        onCompletion?()
      }
    }
    
    if let timer = currentTimer {
      RunLoop.current.add(timer, forMode: .common)
    }
  }
  
  /// easeInOut 곡선
  /// - Parameter t: 진행률 (0.0 ~ 1.0)
  /// - Returns: easing이 적용된 값
  private func easeInOut(_ time: Float) -> Float {
    return time * time * (3.0 - 2.0 * time)
  }
  
  /// easeOut 곡선 (천천히 시작)
  private func easeOut(_ time: Float) -> Float {
    return 1 - (1 - time) * (1 - time)
  }
  
  /// easeIn 곡선 (급격한 증가)
  private func easeIn(_ time: Float) -> Float {
    return time * time
  }
}

// MARK: - 추가 PointLight 기능들

extension LightManager {
  
  /// 여러 PointLight를 동시에 생성해서 더 강력한 효과
  /// - Parameter content: RealityViewContent
  func setupMultipleWhiteOutLights(in content: RealityViewContent) {
    cleanup() // 기존 조명 정리
    
    let positions = [
      SIMD3<Float>(0, 3, 0),    // 중앙 위
      SIMD3<Float>(2, 2, 0),    // 우측
      SIMD3<Float>(-2, 2, 0),   // 좌측
      SIMD3<Float>(0, 2, 2),    // 앞쪽
      SIMD3<Float>(0, 2, -2)    // 뒤쪽
    ]
    
    let parentEntity = Entity()
    parentEntity.name = "whiteOutLightGroup"
    
    for (index, position) in positions.enumerated() {
      let lightEntity = Entity()
      lightEntity.name = "whiteOutLight_\(index)"
      
      var light = PointLightComponent()
      light.color = .white
      light.intensity = 100
      light.attenuationRadius = 30.0
      
      lightEntity.components.set(light)
      lightEntity.position = position
      
      parentEntity.addChild(lightEntity)
    }
    
    content.add(parentEntity)
    whiteOutLight = parentEntity
    
    print("🔆 LightManager: 다중 PointLight 설정 완료 (\(positions.count)개)")
  }
  
  /// 다중 PointLight 애니메이션
  func startMultipleWhiteOutEffect(onCompletion: (() -> Void)? = nil) {
    guard let lightGroup = whiteOutLight else {
      print("❌ LightManager: 다중 WhiteOut 조명이 설정되지 않았습니다")
      return
    }
    
    print("🔆 LightManager: 다중 WhiteOut 효과 시작")
    
    currentTimer?.invalidate()
    
    let startTime = Date()
    let duration: TimeInterval = 8.0
    
    currentTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] timer in
      guard let self = self else {
        timer.invalidate()
        return
      }
      
      let elapsed = Date().timeIntervalSince(startTime)
      let progress = min(elapsed / duration, 1.0)
      
      let easedProgress = self.easeInOut(Float(progress))
      let currentIntensity = 100 + (200000 - 100) * easedProgress
      
      // 모든 자식 PointLight 업데이트
      for child in lightGroup.children {
        guard var lightComponent = child.components[PointLightComponent.self] else { continue }
        
        // 각 조명마다 약간씩 다른 intensity (깜빡이는 효과)
        let variation = sin(Float(elapsed) * 10.0 + Float(child.hashValue)) * 0.1 + 1.0
        lightComponent.intensity = currentIntensity * variation
        child.components.set(lightComponent)
      }
      
      if progress >= 1.0 {
        timer.invalidate()
        self.currentTimer = nil
        print("🔆 LightManager: 다중 WhiteOut 효과 완료!")
        onCompletion?()
      }
    }
    
    if let timer = currentTimer {
      RunLoop.current.add(timer, forMode: .common)
    }
  }
  
  /// PointLight 위치를 동적으로 변경
  /// - Parameter newPosition: 새로운 위치
  func moveWhiteOutLight(to newPosition: SIMD3<Float>) {
    guard let lightEntity = whiteOutLight else {
      print("❌ LightManager: WhiteOut 조명이 설정되지 않았습니다")
      return
    }
    
    lightEntity.position = newPosition
    print("🔆 LightManager: PointLight 위치 변경됨 - \(newPosition)")
  }
  
  /// PointLight 색상을 변경
  /// - Parameter color: 새로운 색상
  func changeWhiteOutLightColor(to color: UIColor) {
    guard let lightEntity = whiteOutLight,
          var lightComponent = lightEntity.components[PointLightComponent.self] else {
      print("❌ LightManager: WhiteOut 조명이 설정되지 않았습니다")
      return
    }
    
    lightComponent.color = color
    lightEntity.components.set(lightComponent)
    print("🔆 LightManager: PointLight 색상 변경됨")
  }
}
