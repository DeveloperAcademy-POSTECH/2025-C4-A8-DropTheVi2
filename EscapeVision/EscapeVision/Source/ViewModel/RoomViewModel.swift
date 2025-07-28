//
//  RoomViewModel.swift
//  EscapeTest
//
//  Created by 조재훈 on 7/13/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

// SwitchComponent 정의 (스코프 문제 해결)
struct SwitchComponent: Component {
  let switchIndex: Int
  let handleCount: Int
  
  init(switchIndex: Int, handleCount: Int = 1) {
    self.switchIndex = switchIndex
    self.handleCount = handleCount
  }
}

// 핸들 상태 관리를 위한 컴포넌트
struct HandleComponent: Component {
  let switchIndex: Int
  var isAttached: Bool
  var isBeingDragged: Bool
  
  init(switchIndex: Int, isAttached: Bool = false, isBeingDragged: Bool = false) {
    self.switchIndex = switchIndex
    self.isAttached = isAttached
    self.isBeingDragged = isBeingDragged
  }
}

@MainActor
@Observable
final class RoomViewModel {
  static let shared = RoomViewModel()
  private init() {}
  
  var rootEntity = Entity()
  
  private var worldAnchor: AnchorEntity?
  
  // 매니저 인스턴스들
  private let cameraTrackingManager = CameraTrackingManager.shared
  private let sceneLoader = SceneLoader.shared
  private let switchManager = SwitchManager.shared
  private let handleManager = HandleManager.shared
  private let collisionManager = CollisionManager.shared
  
  // 카메라 정보 접근을 위한 계산 속성들
  var currentCameraTransform: simd_float4x4 {
    cameraTrackingManager.currentCameraTransform
  }
  
  var currentCameraForward: SIMD3<Float> {
    cameraTrackingManager.currentCameraForward
  }
  
  var currentCameraRight: SIMD3<Float> {
    cameraTrackingManager.currentCameraRight
  }
  
  var currentCameraPosition: SIMD3<Float> {
    cameraTrackingManager.currentCameraPosition
  }

  // MARK: - Setup
  
  func setup() async {
    let anchor = AnchorEntity(world: matrix_identity_float4x4)
    self.worldAnchor = anchor
    rootEntity.addChild(anchor)
    
    // ARKit 세션 시작 (카메라 추적용)
    await cameraTrackingManager.setupARKitSession()
    
    await sceneLoader.loadRoom(into: anchor)
    await sceneLoader.loadObject(into: anchor)
    
    // 새로운 Room 파일 구조 분석
    let entitySearchManager = EntitySearchManager.shared
    entitySearchManager.analyzeRoomStructure(from: rootEntity)
    
    // Room 엔티티에서 Switch 관련 엔티티들 찾기 시도
    if let roomEntity = entitySearchManager.findRoomEntity(from: rootEntity) {
      print("🔍 === Switch 엔티티 검색 시작 ===")
      
      // Switch1~5 찾기 시도
      for switchIndex in 1...5 {
        if let switchEntity = entitySearchManager.findSwitchEntity(in: roomEntity, switchNumber: switchIndex) {
          print("✅ Switch\(switchIndex) 발견: \(switchEntity.name)")
          
          // Switch 내부 구조 분석
          print("  Switch\(switchIndex) 자식들:")
          for (index, child) in switchEntity.children.enumerated() {
            print("    \(index): \(child.name)")
          }
        } else {
          print("❌ Switch\(switchIndex) 찾을 수 없음")
        }
      }
      
      // Switch 키워드로 일반 검색
      print("🔍 Switch 키워드로 일반 검색:")
      searchEntitiesWithKeyword(in: roomEntity, keyword: "switch")
      
      // Floor 관련 엔티티 검색
      print("🔍 Floor 키워드로 일반 검색:")
      searchEntitiesWithKeyword(in: roomEntity, keyword: "floor")
    } else {
      print("❌ Room 엔티티를 찾을 수 없어서 Switch 검색 불가")
    }
    
    // Switch Handle 설정 (매니저 사용)
    await switchManager.setupSwitchHandles(rootEntity: rootEntity)
    
    // 바닥 충돌 컴포넌트 설정 (매니저 사용)
    await collisionManager.setupFloorCollision(from: rootEntity)
    
    // 책상 충돌 컴포넌트 설정 (매니저 사용)
    await collisionManager.setupDeskCollision(from: rootEntity)
    
    // Switch1 Handle1 숨김 및 HandleDetached 설정
    if let worldAnchor = worldAnchor {
      await handleManager.setupSwitch1WithDetachedHandle(from: rootEntity, worldAnchor: worldAnchor)
    }
    
    print("RoomViewModel anchor 설정 성공")
  }
  
  // MARK: - Helper Methods
  
  func getAnchor() -> AnchorEntity? {
    return worldAnchor
  }
  
  func playOpenLidAnimation() {
    // HandleAnimationManager를 통해 애니메이션 실행
    let animationManager = HandleAnimationManager.shared
    animationManager.playOpenLidAnimation()
  }
  
  // MARK: - Public Interface Methods (delegate to managers)
  
  /// Switch 상태 토글 및 애니메이션 실행 (매니저에 위임)
  func toggleSwitchState(switchEntity: Entity, handleEntity: Entity, isUpward: Bool) {
    switchManager.toggleSwitchState(switchEntity: switchEntity, handleEntity: handleEntity, isUpward: isUpward)
  }
  
  /// Handle을 원래 위치로 되돌리기 (매니저에 위임)
  func resetHandlePosition(handleEntity: Entity) {
    switchManager.resetHandlePosition(handleEntity: handleEntity)
  }
  
  /// 핸들과 스위치의 오버랩 감지 (매니저에 위임)
  func checkHandleOverlap(handle: Entity) -> Bool {
    return handleManager.checkHandleOverlap(handle: handle, from: rootEntity)
  }
  
  /// 핸들을 스위치에 끼우기 (매니저에 위임)
  func attachHandleToSwitch(handle: Entity) {
    handleManager.attachHandleToSwitch(handle: handle, from: rootEntity)
  }
  
  /// 핸들이 끼워져 있는지 확인 (매니저에 위임)
  func isHandleAttached(switchIndex: Int) -> Bool {
    return handleManager.isHandleAttached(switchIndex: switchIndex)
  }
  
  /// 분리된 핸들 가져오기 (매니저에 위임)
  func getDetachedHandle(switchIndex: Int) -> Entity? {
    return handleManager.getDetachedHandle(switchIndex: switchIndex)
  }
  
  // MARK: - Search Utilities
  
  /// 특정 키워드로 엔티티 검색 (디버깅용)
  private func searchEntitiesWithKeyword(in parent: Entity, keyword: String, depth: Int = 0) {
    let indent = String(repeating: "  ", count: depth)
    
    // 현재 엔티티 체크
    if parent.name.lowercased().contains(keyword.lowercased()) {
      print("\(indent)🎯 \(keyword) 관련 엔티티 발견: \(parent.name)")
    }
    
    // 자식들도 재귀적으로 검색 (최대 3레벨까지)
    if depth < 3 {
      for child in parent.children {
        searchEntitiesWithKeyword(in: child, keyword: keyword, depth: depth + 1)
      }
    }
  }
}

extension Entity {
  func findDraggableParent() -> Entity? {
    var currentEntity: Entity? = self
    
    while let entity = currentEntity {
      if entity.components[DraggableComponent.self] != nil {
        return entity
      }
      currentEntity = entity.parent
    }
    return nil
  }
}
