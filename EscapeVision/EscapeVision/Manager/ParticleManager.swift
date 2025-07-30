//
//  ParticleManager.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/24/25.
//

import Foundation
import RealityKit

// MARK: - Particle Manager
@MainActor
final class ParticleManager: ObservableObject {
  static let shared = ParticleManager()
  
  private var particleEntity: Entity?
  
  private init() {}
  
  func setParticleEntity(_ entity: Entity) {
    self.particleEntity = entity
    print("✅ ParticleManager: Particle entity 설정됨 - \(entity.name)")
  }
  
  func playParticle(at position: SIMD3<Float>? = nil) {
    guard let particleEntity = particleEntity else {
      print("❌ ParticleManager: Particle entity가 설정되지 않음")
      return
    }
    
    if let newPosition = position {
          particleEntity.setPosition(newPosition, relativeTo: nil)
          print("✅ ParticleManager: Particle 위치 설정됨 - \(newPosition)")
        }
    
    print("✅ ParticleManager: Particle 재생 시작")
    
    // ParticleEmitterComponent가 있는지 확인하고 재생
    if var particleEmitter = particleEntity.components[ParticleEmitterComponent.self] {
      particleEmitter.isEmitting = true
      particleEntity.components[ParticleEmitterComponent.self] = particleEmitter
      print("✅ ParticleManager: ParticleEmitter 활성화됨")
    }
  }
  
  func stopParticle() {
    guard let particleEntity = particleEntity else {
      print("❌ ParticleManager: Particle entity가 설정되지 않음")
      return
    }
    
    print("🛑 ParticleManager: Particle 중지")
    
    // ParticleEmitterComponent가 있는지 확인하고 중지
    if var particleEmitter = particleEntity.components[ParticleEmitterComponent.self] {
      particleEmitter.isEmitting = false
      particleEntity.components[ParticleEmitterComponent.self] = particleEmitter
      print("✅ ParticleManager: ParticleEmitter 비활성화됨")
    }
  }
  
  func setParticlePosition(_ position: SIMD3<Float>) {
      guard let particleEntity = particleEntity else {
        print("❌ ParticleManager: Particle entity가 설정되지 않음")
        return
      }
      
      particleEntity.setPosition(position, relativeTo: nil)
      print("ParticleManager: Particle 위치 변경됨 - \(position)")
    }
  
  // 디버깅용 함수
  func debugParticleInfo() {
    guard let particleEntity = particleEntity else {
      print("❌ ParticleManager: Particle entity 없음")
      return
    }
    
    print("ParticleManager Debug Info:")
    print("   - Entity Name: \(particleEntity.name)")
    print("   - Has ParticleEmitter: \(particleEntity.components[ParticleEmitterComponent.self] != nil)")
    print("   - Available Animations: \(particleEntity.availableAnimations.count)")
    
    if let particleEmitter = particleEntity.components[ParticleEmitterComponent.self] {
      print("   - Is Emitting: \(particleEmitter.isEmitting)")
    }
  }
}
