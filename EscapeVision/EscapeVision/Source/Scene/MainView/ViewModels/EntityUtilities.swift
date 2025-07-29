//
//  EntityUtilities.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit

@MainActor
final class EntityUtilities {
  
  // MARK: - Entity Setup Methods
  
  static func setDragEntity(_ entity: Entity, name: String) {
    entity.name = name
    
    // 물리 컴포넌트 추가
    setPhysics(for: entity)
    
    // 드래그 컴포넌트 추가
    entity.components.set(InputTargetComponent())
    
    print("✅ '\(name)' 엔티티에 드래그 기능 추가됨")
  }
  
  static func setPhysics(for entity: Entity) {
    entity.components.set(PhysicsBodyComponent(
      massProperties: PhysicsMassProperties(mass: 0.3),
      material: PhysicsMaterialResource.generate(staticFriction: 0.9, 
                                                dynamicFriction: 0.8, 
                                                restitution: 0.1),
      mode: .dynamic))
    
    let entityBounds = entity.visualBounds(relativeTo: nil)
    let entitySize = entityBounds.max - entityBounds.min
    let size = SIMD3<Float>(max(0.05, entitySize.x), max(0.05, entitySize.y), 
                           max(0.05, entitySize.z))
    entity.components.set(CollisionComponent(
      shapes: [ShapeResource.generateBox(size: size)], 
      mode: .default, filter: .init(group: .default, mask: .all)))
  }
  
  static func setUpLockEntity(in boxEntity: Entity) {
    print("🔍 Box 엔티티 분석 시작...")
    print("📊 Box 이름: \(boxEntity.name)")
    print("📊 Box 자식 수: \(boxEntity.children.count)")
    
    for (index, child) in boxEntity.children.enumerated() {
      print("  자식 \(index): \(child.name)")
      
      // Plane_008이 자물쇠 잠금 해제 패널인 것 같음
      if child.name.contains("Plane_008") {
        print("🔐 자물쇠 패널 발견: \(child.name)")
        child.components.set(InputTargetComponent())
        
        // 선택적으로 하이라이트 머티리얼 적용
        if let modelEntity = child as? ModelEntity {
          var material = SimpleMaterial()
          material.color = .init(tint: .blue, texture: nil)
          modelEntity.model?.materials = [material]
        }
        
        print("✅ '\(child.name)'에 탭 기능 추가됨")
      }
    }
    
    print("🔐 자물쇠 엔티티 설정 완료")
  }
} 