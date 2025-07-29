//
//  LightManager.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/29/25.
//

import Foundation
import SwiftUI
import RealityKit

@MainActor
@Observable
final class LightManager {
    static let shared = LightManager()
    
    private init() {}
    
    // MARK: - Properties
    private var whiteOutLight: Entity?
    private var currentTimer: Timer?
    
    // MARK: - Public Methods
    
    /// WhiteOut 효과용 조명을 설정
    /// - Parameter content: RealityViewContent
    func setupWhiteOutLight(in content: RealityViewContent) {
        let lightEntity = Entity()
        lightEntity.name = "whiteOutLight"
        
        var light = DirectionalLightComponent()
        light.color = .white
        light.intensity = 100
        
        lightEntity.components.set(light)
        lightEntity.position = SIMD3<Float>(0, 2, -2)
        lightEntity.orientation = simd_quatf(angle: Float.pi, axis: SIMD3(1, 0, 0))
        
        content.add(lightEntity)
        whiteOutLight = lightEntity
        
        print("🔆 LightManager: WhiteOut 조명 설정 완료")
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
            to: 1000000,
            duration: 10.0,
            onCompletion: onCompletion
        )
    }
    
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
    
    /// 조명의 intensity를 애니메이션으로 변경
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
            
            guard var lightComponent = entity.components[DirectionalLightComponent.self] else {
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
    
    /// - Parameter t: 진행률 (0.0 ~ 1.0)
    /// - Returns: easing이 적용된 값
    private func easeInOut(_ t: Float) -> Float {
        return t * t * (3.0 - 2.0 * t)
    }
}
