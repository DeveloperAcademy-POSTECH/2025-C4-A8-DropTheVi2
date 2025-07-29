//
//  CollisionManager.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor
final class CollisionManager {
  static let shared = CollisionManager()
  private init() {}
  
  /// 바닥에 충돌 컴포넌트 추가
  func setupFloorCollision(from rootEntity: Entity) async {
    // 유연한 Room 엔티티 찾기
    let entitySearchManager = EntitySearchManager.shared
    guard let roomEntity = entitySearchManager.findRoomEntity(from: rootEntity) else {
      print("⚠️ Room 엔티티를 찾을 수 없음 - 대체 바닥 생성")
      await createFallbackFloor(in: rootEntity)
      return
    }
    
    print("✅ Room 엔티티 발견: \(roomEntity.name)")
    print("🔍 Room 엔티티에서 바닥 검색 중...")
    print("🏠 Room 자식 엔티티들:")
    for (index, child) in roomEntity.children.enumerated() {
      print("  \(index): \(child.name) - 위치: \(child.position)")
    }
    
    // Floor 찾기 (다양한 이름 패턴 시도)
    let floorNames = ["Floor", "floor", "FLOOR", "Ground", "ground"]
    var foundFloor: Entity?
    
    for floorName in floorNames {
      if let floorContainer = roomEntity.findEntity(named: floorName) {
        // Floor 컨테이너 내에서 실제 Floor 엔티티 찾기
        let actualFloor = floorContainer.findEntity(named: "Floor") ?? 
                         floorContainer.findEntity(named: "floor") ?? 
                         floorContainer
        foundFloor = actualFloor
        print("🏠 바닥 발견: \(floorName) -> \(actualFloor.name) - 위치: \(actualFloor.position)")
        break
      }
    }
    
    // 바닥을 찾지 못한 경우 대안 방법 시도
    if foundFloor == nil {
      print("⚠️ 기본 Floor 이름으로 찾을 수 없음 - 대안 검색")
      
      // 모든 자식을 순회하며 바닥으로 보이는 엔티티 찾기
      for child in roomEntity.children {
        let name = child.name.lowercased()
        if name.contains("floor") || name.contains("ground") || name.contains("바닥") {
          foundFloor = child
          print("🏠 대안 바닥 발견: \(child.name)")
          break
        }
      }
    }
    
    if let floorEntity = foundFloor {
      await setupFloorCollisionForEntity(floorEntity)
    } else {
      print("⚠️ 바닥 엔티티를 찾을 수 없음 - 대체 바닥 생성")
      await createFallbackFloor(in: rootEntity)
    }
  }
  
  /// 특정 엔티티에 바닥 충돌 설정
  private func setupFloorCollisionForEntity(_ floorEntity: Entity) async {
    print("🔧 바닥 충돌 설정 시작: \(floorEntity.name)")
    
    // 이미 충돌 컴포넌트가 있는 경우 제거하고 새로 설정
    if floorEntity.components.has(CollisionComponent.self) {
      floorEntity.components.remove(CollisionComponent.self)
      print("🏠 기존 바닥 충돌 컴포넌트 제거")
    }
    
    // 바닥 크기 (매우 크게 설정하여 확실히 커버)
    let floorSize: SIMD3<Float> = [20.0, 0.2, 20.0] // 20m x 20cm x 20m (매우 큰 크기)
    
    // 충돌 컴포넌트 생성 (명시적 collision group 설정)
    let collisionShape = ShapeResource.generateBox(size: floorSize)
    let collisionComponent = CollisionComponent(
      shapes: [collisionShape],
      mode: .default,
      filter: .init(group: .default, mask: .all)
    )
    floorEntity.components.set(collisionComponent)
    
    // 정적 물리 컴포넌트 추가 (더 강한 설정)
    let physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: PhysicsMaterialResource.generate(
        staticFriction: 0.9,     // 매우 높은 마찰력
        dynamicFriction: 0.8,
        restitution: 0.1         // 낮은 반발력
      ),
      mode: .static
    )
    floorEntity.components.set(physicsBody)
    
    print("🏠 바닥 충돌 컴포넌트 설정 완료")
    print("  - 위치: \(floorEntity.position)")
    print("  - 크기: \(floorSize)")
    print("  - 충돌 그룹: default")
    print("  - 물리 모드: static")
  }
  
  /// 대체 바닥 생성 (바닥을 찾을 수 없는 경우)
  private func createFallbackFloor(in rootEntity: Entity) async {
    print("🚧 대체 바닥 생성 중...")
    
    // 투명한 바닥 엔티티 생성
    let floorSize: SIMD3<Float> = [25.0, 0.1, 25.0] // 25m x 10cm x 25m
    
    var floorMaterial = SimpleMaterial()
    floorMaterial.color = .init(tint: UIColor.clear, texture: nil) // 투명
    
    let invisibleFloor = ModelEntity(
      mesh: .generateBox(size: floorSize),
      materials: [floorMaterial]
    )
    
    invisibleFloor.name = "InvisibleFloor"
    invisibleFloor.position = SIMD3<Float>(0, -0.05, 0) // 약간 아래에 배치
    
    // 충돌 컴포넌트 추가
    let collisionShape = ShapeResource.generateBox(size: floorSize)
    let collisionComponent = CollisionComponent(
      shapes: [collisionShape],
      mode: .default,
      filter: .init(group: .default, mask: .all)
    )
    invisibleFloor.components.set(collisionComponent)
    
    // 정적 물리 컴포넌트 추가
    let physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: PhysicsMaterialResource.generate(
        staticFriction: 0.9,
        dynamicFriction: 0.8,
        restitution: 0.1
      ),
      mode: .static
    )
    invisibleFloor.components.set(physicsBody)
    
    // 월드 앵커에 직접 추가
    if let firstRoot = rootEntity.children.first {
      firstRoot.addChild(invisibleFloor)
      print("🚧 대체 바닥 생성 완료 - 위치: \(invisibleFloor.position), 크기: \(floorSize)")
    }
  }
  
  /// 안전 바닥 설정 (확실한 충돌 보장)
  func setupSafetyFloor(in rootEntity: Entity) async {
    print("🛡️ 안전 바닥 설정 중...")
    
    // 매우 큰 투명 안전 바닥 생성
    let safetyFloorSize: SIMD3<Float> = [30.0, 0.05, 30.0] // 30m x 5cm x 30m
    
    var safetyMaterial = SimpleMaterial()
    safetyMaterial.color = .init(tint: UIColor.clear, texture: nil) // 완전 투명
    
    let safetyFloor = ModelEntity(
      mesh: .generateBox(size: safetyFloorSize),
      materials: [safetyMaterial]
    )
    
    safetyFloor.name = "SafetyFloor"
    safetyFloor.position = SIMD3<Float>(0, -0.1, 0) // 바닥보다 약간 아래
    
    // 강력한 충돌 컴포넌트 설정
    let collisionShape = ShapeResource.generateBox(size: safetyFloorSize)
    let collisionComponent = CollisionComponent(
      shapes: [collisionShape],
      mode: .default,
      filter: .init(group: .default, mask: .all)
    )
    safetyFloor.components.set(collisionComponent)
    
    // 매우 강력한 정적 물리 컴포넌트
    let physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: PhysicsMaterialResource.generate(
        staticFriction: 1.0,     // 최대 마찰력
        dynamicFriction: 0.9,
        restitution: 0.0         // 반발력 없음
      ),
      mode: .static
    )
    safetyFloor.components.set(physicsBody)
    
    // 월드 앵커에 직접 추가
    if let firstRoot = rootEntity.children.first {
      firstRoot.addChild(safetyFloor)
      print("🛡️ 안전 바닥 설정 완료")
      print("  - 위치: \(safetyFloor.position)")
      print("  - 크기: \(safetyFloorSize)")
      print("  - 투명도: 100% (보이지 않음)")
      print("  - 마찰력: 최대 (확실한 정지)")
    }
  }
  
  /// 책상에 충돌 컴포넌트 추가
  func setupDeskCollision(from rootEntity: Entity) async {
    // 유연한 Room 엔티티 찾기
    let entitySearchManager = EntitySearchManager.shared
    guard let roomEntity = entitySearchManager.findRoomEntity(from: rootEntity) else {
      print("⚠️ Room 엔티티를 찾을 수 없음 - 책상 충돌 설정 실패")
      return
    }
    
    print("✅ Room 엔티티 발견: \(roomEntity.name)")
    
    // DesKTest_2 찾기 (다양한 이름 패턴 시도)
    let deskNames = ["DesKTest_2", "DeskTest_2", "DeskTest2", "Desk_2", "desk_2", "desktest_2"]
    var foundDesk: Entity?
    
    for deskName in deskNames {
      if let desk = roomEntity.findEntity(named: deskName) {
        foundDesk = desk
        print("📋 책상 발견: \(deskName) - 위치: \(desk.position)")
        break
      }
    }
    
    guard let deskEntity = foundDesk else {
      print("⚠️ DesKTest_2 책상을 찾을 수 없음")
      return
    }
    
    // 책상의 실제 Desk 엔티티 찾기
    let actualDesk = deskEntity.findEntity(named: "Desk") ?? deskEntity
    print("📋 실제 책상 엔티티: \(actualDesk.name) - 위치: \(actualDesk.position)")
    
    // 이미 충돌 컴포넌트가 있는지 확인
    if actualDesk.components.has(CollisionComponent.self) {
      print("📋 책상에 이미 충돌 컴포넌트가 있음")
      return
    }
    
    // 책상 크기 (더 정확한 크기로 조정)
    let deskSize: SIMD3<Float> = [1.5, 0.05, 0.8] // 가로 1.5m, 높이 5cm, 세로 80cm
    
    // 충돌 컴포넌트 생성
    let collisionShape = ShapeResource.generateBox(size: deskSize)
    let collisionComponent = CollisionComponent(shapes: [collisionShape])
    actualDesk.components.set(collisionComponent)
    
    // 정적 물리 컴포넌트 추가 (움직이지 않음)
    let physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: PhysicsMaterialResource.generate(
        staticFriction: 0.9,     // 매우 높은 마찰력 (물체가 미끄러지지 않음)
        dynamicFriction: 0.7,
        restitution: 0.05        // 매우 낮은 반발력 (튀지 않음)
      ),
      mode: .static
    )
    actualDesk.components.set(physicsBody)
    
    print("📋 DesKTest_2 책상에 충돌 컴포넌트 추가 완료 - 크기: \(deskSize)")
  }
  
  /// 다른 오브젝트들에도 충돌 컴포넌트 추가 (필요시)
  func setupGeneralCollisions(from rootEntity: Entity) async {
    // 유연한 Room 엔티티 찾기
    let entitySearchManager = EntitySearchManager.shared
    guard let roomEntity = entitySearchManager.findRoomEntity(from: rootEntity) else {
      print("⚠️ Room 엔티티를 찾을 수 없음 - 일반 충돌 설정 실패")
      return
    }
    
    print("✅ Room 엔티티 발견: \(roomEntity.name)")
    
    // 벽면들에 충돌 컴포넌트 추가
    let wallNames = ["Wall", "wall", "벽", "WALL"]
    for wallName in wallNames {
      if let wall = roomEntity.findEntity(named: wallName) {
        setupWallCollision(wall)
      }
    }
    
    // 다른 가구들에도 충돌 컴포넌트 추가
    let furnitureKeywords = ["bed", "chair", "table", "cabinet", "shelf"]
    for keyword in furnitureKeywords {
      if let furniture = searchEntityByKeyword(in: roomEntity, keyword: keyword) {
        setupFurnitureCollision(furniture, type: keyword)
      }
    }
  }
  
  // MARK: - Private Methods
  
  /// 벽에 충돌 컴포넌트 추가
  private func setupWallCollision(_ wallEntity: Entity) {
    // 이미 충돌 컴포넌트가 있는지 확인
    if wallEntity.components.has(CollisionComponent.self) {
      return
    }
    
    // 벽 크기 (일반적인 벽 크기)
    let wallSize: SIMD3<Float> = [0.2, 3.0, 4.0] // 두께 20cm, 높이 3m, 너비 4m
    
    // 충돌 컴포넌트 생성
    let collisionShape = ShapeResource.generateBox(size: wallSize)
    let collisionComponent = CollisionComponent(shapes: [collisionShape])
    wallEntity.components.set(collisionComponent)
    
    // 정적 물리 컴포넌트 추가
    let physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: PhysicsMaterialResource.generate(
        staticFriction: 0.8,
        dynamicFriction: 0.6,
        restitution: 0.1
      ),
      mode: .static
    )
    wallEntity.components.set(physicsBody)
    
    print("🧱 벽에 충돌 컴포넌트 추가 완료: \(wallEntity.name)")
  }
  
  /// 가구에 충돌 컴포넌트 추가
  private func setupFurnitureCollision(_ furnitureEntity: Entity, type: String) {
    // 이미 충돌 컴포넌트가 있는지 확인
    if furnitureEntity.components.has(CollisionComponent.self) {
      return
    }
    
    // 가구 타입에 따른 크기 설정
    let furnitureSize: SIMD3<Float>
    switch type.lowercased() {
    case "bed":
      furnitureSize = [2.0, 0.6, 1.0] // 침대: 2m x 60cm x 1m
    case "chair":
      furnitureSize = [0.6, 1.0, 0.6] // 의자: 60cm x 1m x 60cm
    case "table":
      furnitureSize = [1.5, 0.8, 1.0] // 테이블: 1.5m x 80cm x 1m
    case "cabinet":
      furnitureSize = [1.0, 2.0, 0.5] // 캐비닛: 1m x 2m x 50cm
    case "shelf":
      furnitureSize = [1.2, 1.8, 0.3] // 선반: 1.2m x 1.8m x 30cm
    default:
      furnitureSize = [1.0, 1.0, 1.0] // 기본 크기
    }
    
    // 충돌 컴포넌트 생성
    let collisionShape = ShapeResource.generateBox(size: furnitureSize)
    let collisionComponent = CollisionComponent(shapes: [collisionShape])
    furnitureEntity.components.set(collisionComponent)
    
    // 정적 물리 컴포넌트 추가
    let physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: PhysicsMaterialResource.generate(
        staticFriction: 0.7,
        dynamicFriction: 0.5,
        restitution: 0.2
      ),
      mode: .static
    )
    furnitureEntity.components.set(physicsBody)
    
    print("🪑 \(type) 가구에 충돌 컴포넌트 추가 완료: \(furnitureEntity.name) - 크기: \(furnitureSize)")
  }
  
  /// 키워드로 엔티티 검색
  private func searchEntityByKeyword(in parent: Entity, keyword: String) -> Entity? {
    for child in parent.children {
      if child.name.lowercased().contains(keyword.lowercased()) {
        return child
      }
      
      // 재귀적으로 자식 엔티티들도 검색
      if let found = searchEntityByKeyword(in: child, keyword: keyword) {
        return found
      }
    }
    return nil
  }
} 
