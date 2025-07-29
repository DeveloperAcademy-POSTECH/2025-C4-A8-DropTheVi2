import RealityKit
import Foundation

/// HandleDetached 엔티티 검색 및 설정 전담 매니저
@MainActor
class HandleDetectionManager {
  private let entitySearchManager: EntitySearchManager
  
  init(entitySearchManager: EntitySearchManager) {
    self.entitySearchManager = entitySearchManager
  }
  
  /// Room에서 기존 HandleDetached 엔티티 찾기 및 설정
  func findAndSetupHandleDetached(from rootEntity: Entity) async -> Entity? {
    print("🔍 HandleDetached 검색 시작")
    
    guard let roomEntity = await entitySearchManager.findRoomEntity(from: rootEntity) else {
      print("❌ Room 엔티티 찾기 실패")
      return nil
    }
    
    guard let handleDetachedContainer = await findHandleDetachedContainer(in: roomEntity) else {
      print("❌ HandleDetached 컨테이너 찾기 실패")
      return nil
    }
    
    let actualHandleEntity = findActualHandleEntity(in: handleDetachedContainer)
    setupBasicComponents(for: actualHandleEntity)
    
    print("✅ HandleDetached 설정 완료")
    return actualHandleEntity
  }
  
  /// HandleDetached 컨테이너 찾기
  private func findHandleDetachedContainer(in roomEntity: Entity) async -> Entity? {
    let possibleNames = ["HandleDetached", "handleDetached", "HandleDetach", "Handle_Detached", "handle_detached"]
    
    for name in possibleNames {
      if let entity = roomEntity.findEntity(named: name) {
        print("✅ HandleDetached 컨테이너 발견: \(name)")
        return entity
      }
    }
    
    if let entity = entitySearchManager.findEntityContainingKeyword(keyword: "HandleDetached", in: roomEntity) {
      print("✅ 키워드 검색 성공: \(entity.name)")
      return entity
    }
    
    return nil
  }
  
  /// 실제 핸들 엔티티 찾기
  private func findActualHandleEntity(in container: Entity) -> Entity {
    print("🔍 HandleDetached 내부 구조 분석:")
    printEntityStructure(container, depth: 0, maxDepth: 3)
    
    // 1. Sphere_005_005 ModelEntity 찾기
    if let sphereEntity = findEntityRecursive(in: container, name: "Sphere_005_005") {
      print("✅ 실제 핸들 모델 발견: Sphere_005_005")
      return sphereEntity
    }
    
    // 2. 중첩된 HandleDetached 찾기
    if let nestedHandle = findEntityRecursive(in: container, name: "HandleDetached", excluding: container) {
      print("✅ 중첩된 HandleDetached 발견")
      return nestedHandle
    }
    
    // 3. 첫 번째 ModelEntity 찾기
    if let firstModel = findFirstModelEntity(in: container) {
      print("✅ 첫 번째 ModelEntity 발견: \(firstModel.name)")
      return firstModel
    }
    
    print("⚠️ 실제 모델 찾기 실패, 컨테이너 사용")
    return container
  }
  
  /// 기본 컴포넌트 설정
  private func setupBasicComponents(for entity: Entity) {
    print("🔧 HandleDetached 설정 대상:")
    print("  - 엔티티: \(entity.name)")
    print("  - 월드 위치: \(entity.convert(position: entity.position, to: nil))")
    
    entity.components.remove(PhysicsBodyComponent.self)
    entity.components.remove(CollisionComponent.self)
  }
  
  /// 엔티티 구조 출력
  private func printEntityStructure(_ entity: Entity, depth: Int, maxDepth: Int) {
    let indent = String(repeating: "  ", count: depth)
    let worldPos = entity.convert(position: entity.position, to: nil)
    print("\(indent)📦 \(entity.name) - 월드: \(worldPos)")
    
    if depth < maxDepth {
      for child in entity.children.prefix(2) {
        printEntityStructure(child, depth: depth + 1, maxDepth: maxDepth)
      }
    }
  }
  
  /// 재귀적으로 특정 이름의 엔티티 찾기
  private func findEntityRecursive(in entity: Entity, name: String, excluding: Entity? = nil) -> Entity? {
    if entity.name == name && entity !== excluding {
      return entity
    }
    
    for child in entity.children {
      if let found = findEntityRecursive(in: child, name: name, excluding: excluding) {
        return found
      }
    }
    
    return nil
  }
  
  /// 첫 번째 ModelEntity 찾기
  private func findFirstModelEntity(in entity: Entity) -> ModelEntity? {
    if let modelEntity = entity as? ModelEntity {
      return modelEntity
    }
    
    for child in entity.children {
      if let found = findFirstModelEntity(in: child) {
        return found
      }
    }
    
    return nil
  }
}