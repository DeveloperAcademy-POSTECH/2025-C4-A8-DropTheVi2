//
//  EntitySearchManager.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor
final class EntitySearchManager {
  static let shared = EntitySearchManager()
  private init() {}
  
  /// Switch 엔티티 찾기 (다양한 이름 패턴 시도)
  func findSwitchEntity(in roomEntity: Entity, switchNumber: Int) -> Entity? {
    let possibleNames = [
      "Switch\(switchNumber)",
      "switch\(switchNumber)", 
      "Switch_\(switchNumber)",
      "switch_\(switchNumber)",
      "SWITCH\(switchNumber)",
      "switchSingle\(switchNumber)",
      "SwitchSingle\(switchNumber)"
    ]
    
    for name in possibleNames {
      if let entity = roomEntity.findEntity(named: name) {
        print("Switch\(switchNumber) 발견: '\(name)'")
        return entity
      }
    }
    
    // 이름에 switch가 포함된 엔티티들을 재귀적으로 찾기
    return findEntityContaining(keyword: "switch", in: roomEntity, targetNumber: switchNumber)
  }
  
  /// Handle 엔티티 찾기 (다양한 이름 패턴 시도)
  func findHandleEntity(in switchEntity: Entity, handleNumber: Int) -> Entity? {
    let possibleNames = [
      "Handle\(handleNumber)",
      "handle\(handleNumber)",
      "Handle_\(handleNumber)", 
      "handle_\(handleNumber)",
      "HANDLE\(handleNumber)",
      "Lever\(handleNumber)",
      "lever\(handleNumber)"
    ]
    
    for name in possibleNames {
      if let entity = switchEntity.findEntity(named: name) {
        print("Handle\(handleNumber) 발견: '\(name)'")
        return entity
      }
    }
    
    // 이름에 handle이나 lever가 포함된 엔티티들을 재귀적으로 찾기
    return findEntityContaining(keyword: "handle", in: switchEntity, targetNumber: handleNumber) ??
           findEntityContaining(keyword: "lever", in: switchEntity, targetNumber: handleNumber)
  }
  
  /// 특정 키워드와 번호가 포함된 엔티티 찾기
  func findEntityContaining(keyword: String, in parent: Entity, targetNumber: Int) -> Entity? {
    for child in parent.children {
      let lowercaseName = child.name.lowercased()
      if lowercaseName.contains(keyword.lowercased()) && lowercaseName.contains("\(targetNumber)") {
        print("키워드 '\(keyword)' 및 번호 '\(targetNumber)' 포함 엔티티 발견: '\(child.name)'")
        return child
      }
      
      // 재귀적으로 자식 엔티티들도 검색
      if let found = findEntityContaining(keyword: keyword, in: child, targetNumber: targetNumber) {
        return found
      }
    }
    return nil
  }
  
  /// 키워드로 엔티티 검색
  func searchEntityByKeyword(in parent: Entity, keyword: String) -> Entity? {
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
  
  /// 특정 키워드가 포함된 엔티티 찾기 (번호 없음)
  func findEntityContainingKeyword(keyword: String, in parent: Entity) -> Entity? {
    for child in parent.children {
      let lowercaseName = child.name.lowercased()
      if lowercaseName.contains(keyword.lowercased()) {
        print("키워드 '\(keyword)' 포함 엔티티 발견: '\(child.name)'")
        return child
      }
      
      // 재귀적으로 자식 엔티티들도 검색
      if let found = findEntityContainingKeyword(keyword: keyword, in: child) {
        return found
      }
    }
    return nil
  }
  
  /// 엔티티 계층 구조 출력 (디버깅용)
  private func printEntityHierarchy(_ entity: Entity, depth: Int, maxDepth: Int) {
    guard depth <= maxDepth else { return }
    
    let indent = String(repeating: "  ", count: depth)
    print("\(indent)📋 \(entity.name) (타입: \(type(of: entity)), 자식: \(entity.children.count))")
    
    for child in entity.children {
      printEntityHierarchy(child, depth: depth + 1, maxDepth: maxDepth)
    }
  }
  
  /// Room 엔티티 구조 분석
  func analyzeRoomStructure(from rootEntity: Entity) {
    print("🔍 === Room 엔티티 구조 분석 ===")
    print("📊 RootEntity 이름: \(rootEntity.name)")
    print("📊 RootEntity 자식 수: \(rootEntity.children.count)")
    
    // 첫 번째 레벨 분석
    for (index, child) in rootEntity.children.enumerated() {
      print("  레벨 1 - \(index): \(child.name) (자식: \(child.children.count)개)")
      
      // 두 번째 레벨 분석
      for (childIndex, grandChild) in child.children.enumerated() {
        print("    레벨 2 - \(childIndex): \(grandChild.name) (자식: \(grandChild.children.count)개)")
        
        // Room 후보 체크
        if grandChild.name.lowercased().contains("room") {
          print("      🎯 Room 후보 발견!")
        }
      }
    }
    
    // 유연한 Room 찾기 시도
    if let foundRoom = findRoomEntity(from: rootEntity) {
      print("✅ Room 엔티티 찾기 성공: \(foundRoom.name)")
      analyzeRoomContent(foundRoom)
    } else {
      print("❌ Room 엔티티를 찾을 수 없음")
    }
  }
  
  /// Room 내용 분석
  private func analyzeRoomContent(_ roomEntity: Entity) {
    print("🏠 === Room 내용 분석 ===")
    print("📊 Room 이름: \(roomEntity.name)")
    print("📊 Room 자식 수: \(roomEntity.children.count)")
    
    for (index, child) in roomEntity.children.enumerated() {
      print("  \(index): \(child.name) - 위치: \(child.position)")
      
      // Switch 관련 엔티티 체크
      if child.name.lowercased().contains("switch") {
        print("    🎯 Switch 발견!")
      }
      
      // Floor 관련 엔티티 체크
      if child.name.lowercased().contains("floor") || child.name.lowercased().contains("ground") {
        print("    🏠 Floor 발견!")
      }
    }
  }
  
  /// DeskTest_2 책상 위치 찾기
  func findDeskPosition(from rootEntity: Entity) async -> SIMD3<Float> {
    // 유연한 Room 엔티티 찾기
    guard let roomEntity = findRoomEntity(from: rootEntity) else {
      print("⚠️ Room 엔티티를 찾을 수 없음 - 기본 위치 반환")
      return SIMD3<Float>(-1.5, 1.0, 0.5) // 기본 위치
    }
    
    print("✅ Room 엔티티 발견: \(roomEntity.name)")
    print("🔍 Room 엔티티에서 DesKTest_2 검색 중...")
    
    // DesKTest_2 찾기 (정확한 이름 우선)
    let deskNames = ["DesKTest_2", "DeskTest_2", "DeskTest2", "Desk_2", "desk_2", "desktest_2"]
    var foundDeskContainer: Entity?
    
    for deskName in deskNames {
      if let desk = roomEntity.findEntity(named: deskName) {
        foundDeskContainer = desk
        print("📋 책상 컨테이너 발견: \(deskName) - 위치: \(desk.position)")
        break
      }
    }
    
    if let deskContainer = foundDeskContainer {
      // DesKTest_2 내에서 실제 Desk 객체 찾기
      let actualDesk = deskContainer.findEntity(named: "Desk") ?? 
                      deskContainer.findEntity(named: "desk") ?? 
                      deskContainer
      
      print("📋 실제 책상 엔티티 발견: \(actualDesk.name) - 위치: \(actualDesk.position)")
      
      // 책상 표면 위 15cm에 핸들 배치 (책상의 가장 넓은 면 위)
      let deskTopPosition = SIMD3<Float>(
        actualDesk.position.x,
        actualDesk.position.y + 0.15, // 책상 표면 위 15cm
        actualDesk.position.z
      )
      
      print("📍 최종 책상 위 위치: \(deskTopPosition)")
      return deskTopPosition
    }
    
    // Desk 키워드로 일반 검색
    let foundDesk = searchEntityByKeyword(in: roomEntity, keyword: "desk")
    if let desk = foundDesk {
      print("📋 키워드 검색으로 책상 발견 (\(desk.name))! 위치: \(desk.position)")
      
      let deskTopPosition = SIMD3<Float>(
        desk.position.x,
        desk.position.y + 0.15,
        desk.position.z
      )
      
      return deskTopPosition
    }
    
    // Table 키워드로도 검색
    let foundTable = searchEntityByKeyword(in: roomEntity, keyword: "table")
    if let table = foundTable {
      print("📋 키워드 검색으로 테이블 발견 (\(table.name))! 위치: \(table.position)")
      
      let tableTopPosition = SIMD3<Float>(
        table.position.x,
        table.position.y + 0.15,
        table.position.z
      )
      
      return tableTopPosition
    }
    
    print("⚠️ 책상이나 테이블을 찾을 수 없음")
    
    // 이미지에서 보이는 책상 위치로 추정 (임시)
    print("📍 추정 책상 위치 사용 (이미지 기준)")
    return SIMD3<Float>(-1.5, 1.2, 0.5) // 책상으로 보이는 위치 추정 (높이 조정)
  }
  
  /// 두 점 사이의 거리 계산
  func distance(_ firstPoint: SIMD3<Float>, _ secondPoint: SIMD3<Float>) -> Float {
    let diff = firstPoint - secondPoint
    return sqrt(diff.x * diff.x + diff.y * diff.y + diff.z * diff.z)
  }
  
  /// Room 엔티티를 유연하게 찾기 (6가지 전략)
  func findRoomEntity(from rootEntity: Entity) -> Entity? {
    print("🔍 유연한 Room 엔티티 검색 시작...")
    
    // 전략 1: 직접 "Room" 이름으로 찾기
    if let room = rootEntity.findEntity(named: "Room") {
      print("✅ 전략 1 성공: 직접 Room 발견 - \(room.name)")
      return room
    }
    
    // 전략 2: TestScene 구조 처리 (Root -> Room)
    for child in rootEntity.children {
      if child.name == "Root" || child.name.isEmpty {
        // Root 엔티티 내부에서 Room 찾기
        if let room = child.findEntity(named: "Room") {
          print("✅ 전략 2 성공: Root 내부에서 Room 발견 - \(room.name)")
          return room
        }
        
        // Root의 자식들 중에서 Room 관련 엔티티 찾기
        for grandChild in child.children {
          if grandChild.name.lowercased().contains("room") {
            print("✅ 전략 2-1 성공: Root 내부에서 Room 관련 엔티티 발견 - \(grandChild.name)")
            return grandChild
          }
        }
      }
    }
    
    // 전략 3: 첫 번째 자식의 자식들에서 Room 찾기 (중첩 구조 처리)
    if let firstChild = rootEntity.children.first {
      for grandChild in firstChild.children {
        if grandChild.name.lowercased().contains("room") {
          print("✅ 전략 3 성공: 중첩 구조에서 Room 발견 - \(grandChild.name)")
          return grandChild
        }
      }
    }
    
    // 전략 4: 재귀적으로 모든 하위 엔티티에서 Room 찾기
    if let room = recursivelyFindRoom(in: rootEntity, depth: 0, maxDepth: 4) {
      print("✅ 전략 4 성공: 재귀 검색으로 Room 발견 - \(room.name)")
      return room
    }
    
    // 전략 5: Switch 키워드가 있는 엔티티의 부모 찾기 (Room이 Switch들을 포함한다고 가정)
    if let switchContainer = findSwitchContainerEntity(in: rootEntity) {
      print("✅ 전략 5 성공: Switch 컨테이너를 Room으로 간주 - \(switchContainer.name)")
      return switchContainer
    }
    
    // 전략 6: 자식이 많은 엔티티를 Room으로 간주 (Room은 보통 많은 가구를 포함)
    var candidateRoom: Entity?
    var maxChildCount = 0
    
    func findLargestContainer(entity: Entity, depth: Int) {
      if depth > 3 { return } // 최대 3레벨까지만
      
      if entity.children.count > maxChildCount && entity.children.count >= 3 {
        maxChildCount = entity.children.count
        candidateRoom = entity
      }
      
      for child in entity.children {
        findLargestContainer(entity: child, depth: depth + 1)
      }
    }
    
    findLargestContainer(entity: rootEntity, depth: 0)
    
    if let room = candidateRoom {
      print("✅ 전략 6 성공: 가장 많은 자식을 가진 엔티티를 Room으로 간주 - \(room.name) (자식 \(room.children.count)개)")
      return room
    }
    
    print("❌ 모든 전략으로 Room을 찾을 수 없음")
    
    // 디버깅: 전체 구조 출력
    print("🔍 === 전체 엔티티 구조 (디버깅) ===")
    printEntityHierarchy(rootEntity, depth: 0, maxDepth: 3)
    
    return nil
  }
  
  /// 재귀적으로 Room 엔티티 찾기 (maxDepth 추가)
  private func recursivelyFindRoom(in entity: Entity, depth: Int, maxDepth: Int) -> Entity? {
    // 너무 깊이 들어가지 않도록 제한
    guard depth < maxDepth else { return nil }
    
    // 현재 엔티티가 Room인지 확인
    let lowercaseName = entity.name.lowercased()
    if lowercaseName == "room" || lowercaseName.contains("room") {
      return entity
    }
    
    // 자식들에서 재귀적으로 검색
    for child in entity.children {
      if let found = recursivelyFindRoom(in: child, depth: depth + 1, maxDepth: maxDepth) {
        return found
      }
    }
    
    return nil
  }
  
  /// Switch 관련 엔티티들이 포함된 컨테이너 찾기
  private func findSwitchContainerEntity(in rootEntity: Entity) -> Entity? {
    var switchCount = 0
    var containerEntity: Entity?
    
    func countSwitches(in entity: Entity, depth: Int) {
      if depth > 4 { return }
      
      var currentSwitchCount = 0
      
      // 현재 엔티티에서 직접 switch 찾기
      for child in entity.children {
        if child.name.lowercased().contains("switch") {
          currentSwitchCount += 1
        }
      }
      
      // 더 많은 스위치를 포함한 엔티티 발견
      if currentSwitchCount > switchCount {
        switchCount = currentSwitchCount
        containerEntity = entity
      }
      
      // 자식들도 재귀적으로 검사
      for child in entity.children {
        countSwitches(in: child, depth: depth + 1)
      }
    }
    
    countSwitches(in: rootEntity, depth: 0)
    
    if switchCount >= 2 { // 최소 2개 이상의 스위치가 있어야 Room으로 간주
      print("🎯 Switch 컨테이너 발견: \(containerEntity?.name ?? "Unknown") (스위치 \(switchCount)개)")
      return containerEntity
    }
    
    return nil
  }
  
  /// Floor 엔티티 찾기
  func findFloor() -> Entity? {
    // RoomViewModel에서 rootEntity를 가져와서 검색
    let roomViewModel = RoomViewModel.shared
    let rootEntity = roomViewModel.rootEntity
    
    // Room 엔티티 내에서 Floor 찾기
    if let roomEntity = findRoomEntity(from: rootEntity) {
      return findFloorInRoom(roomEntity)
    }
    
    // Room을 찾지 못하면 root에서 직접 검색
    return findFloorInRoom(rootEntity)
  }
  
  /// Room 엔티티 내에서 Floor 찾기
  private func findFloorInRoom(_ roomEntity: Entity) -> Entity? {
    let possibleFloorNames = [
      "Floor",
      "floor", 
      "FLOOR",
      "Floor_01",
      "floor_01",
      "Ground",
      "ground",
      "Base",
      "base"
    ]
    
    // 직접 이름으로 찾기
    for floorName in possibleFloorNames {
      if let floorEntity = roomEntity.findEntity(named: floorName) {
        print("🏠 [Floor 발견] 이름: '\(floorName)' - 엔티티: \(floorEntity.name)")
        return floorEntity
      }
    }
    
    // 이름에 "floor" 키워드가 포함된 엔티티 찾기
    return findEntityContainingKeyword(keyword: "floor", in: roomEntity)
  }
  
  /// Joint 엔티티 찾기 (다양한 이름 패턴 시도)
  func findJointEntity(in switchEntity: Entity, jointNumber: Int) -> Entity? {
    let possibleNames = [
      "Joint\(jointNumber)",
      "joint\(jointNumber)",
      "Joint_\(jointNumber)",
      "joint_\(jointNumber)",
      "JOINT\(jointNumber)",
      "Pivot\(jointNumber)",
      "pivot\(jointNumber)"
    ]
    
    for name in possibleNames {
      if let entity = switchEntity.findEntity(named: name) {
        print("🔗 [Joint 발견] 이름: '\(name)' - 엔티티: \(entity.name)")
        return entity
      }
    }
    
    // 이름에 joint가 포함된 엔티티들을 재귀적으로 찾기
    return findEntityContaining(keyword: "joint", in: switchEntity, targetNumber: jointNumber)
  }
} 
