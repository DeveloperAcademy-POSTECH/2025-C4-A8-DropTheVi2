//
//  RoomViewModel.swift
//  EscapeTest
//
//  Created by 조재훈 on 7/13/25.
//

import Foundation
import RealityKit
import RealityKitContent
import ARKit
import SwiftUI

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

// swiftlint:disable type_body_length

@MainActor
@Observable
final class RoomViewModel {
  static let shared = RoomViewModel()
  
  private init() {}
  
  var rootEntity = Entity()
  var isPresented: Bool = false
  
  private var worldAnchor: AnchorEntity?
  
  private let soundManager = SoundManager.shared
  
  // 매니저 인스턴스들
  private let cameraTrackingManager = CameraTrackingManager.shared
  private let sceneLoader = SceneLoader.shared
  private let switchManager = SwitchManager.shared
  private let handleManager = HandleManager.shared
  private let collisionManager = CollisionManager.shared
  private var particleManager = ParticleManager.shared
  
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
    
    await loadRoom(into: anchor)
    await loadObject(into: anchor)
    
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
    
    NotificationCenter.default.addObserver(forName: Notification.Name("openBox"), object: nil, queue: .main) { _ in
      print("박스 알림 수신")
      self.openBox()
      DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
        self.soundManager
          .playSound(.gasAlert, volume: 1.0)
      }
    }
    NotificationCenter.default.addObserver(forName: Notification.Name("openDrawer"), object: nil, queue: .main) { _ in
      print("서랍 알림 수신")
      self.openDrawer()
      self.soundManager.playSound(.openDesk, volume: 1.0)
    }
    NotificationCenter.default.addObserver(forName: Notification.Name("openVent"), object: nil, queue: .main) { _ in
      print("환풍구 오픈 알림 수신")
      self.openVent()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.soundManager
          .playSound(.ventOpen, volume: 1.0)
      }
    }
  }
  // MARK: - Scene Loading
  
  private func loadRoom(into anchor: AnchorEntity) async {
    // 전체 씬 불러오기
    guard
      let roomEntity = try? await Entity(
        named: "Final",
        in: realityKitContentBundle
      )
    else {
      print("방 불러오기 실패")
      return
    }
    
    if let boxTest = roomEntity.findEntity(named: "Box") {
      setUpLockEntity(in: boxTest)
      print("박스 설정 성공")
    } else {
      print("테스트 박스 설정 실패")
    }
    
    if let machineTest = roomEntity.findEntity(named: "Monitor06_002") {
      setUpMonitorEntity(in: machineTest)
      print("모니터 설정 성공")
    } else {
      print("모니터 설정 실패")
    }
    
    if let particleEntity = roomEntity.findEntity(named: "Fog_Emitter_1") {
      particleManager.setParticleEntity(particleEntity)
      
      // 디버깅용
      particleManager.debugParticleInfo()
    } else {
      print("❌ RoomViewModel: Fog_Particle_1을 찾을 수 없음")
    }
    
    if let fileEntity = roomEntity.findEntity(named: "FileHolder") {
      setUpFileEntity(in: fileEntity)
      print("\(fileEntity): 파일 엔티티 찾음")
    } else {
      print("파일 못찾았다.")
    }
    
    if let doorTest = roomEntity.findEntity(named: "_DoorKnob") {
      setUpDoorEntity(in: doorTest)
      print("문고리 찾기 성공")
    } else {
      print("문고리 찾기 실패")
    }

    if let drawer = roomEntity.findEntity(named: "Drawer1") {
      setUpDrawerEntity(in: drawer)
      print("책상 서랍 찾기 성공")
    } else {
      print("책상 서랍 찾기 실패")
    }
    
    if let drawerKnob = roomEntity.findEntity(named: "Knob1") {
      setUpKnobEntity(in: drawerKnob)
      print("책상 서랍 손잡이 찾기 성공")
    } else {
      print("책상 서랍 손잡이 찾기 실패")
    }
    
    //환풍구 찾기
    if let ventTest = roomEntity.findEntity(named: "AirVent3_only") {
      setUpVentEntity(in: ventTest)
      print("환풍구 찾기 성공")
    } else {
      print("환풍구 찾기 실패")
    }
    
    if let blackDomeEntity = roomEntity.findEntity(named: "SkyDome") {
      print("✅ SkyDome 엔티티 발견 - 3초 후 제거 예정")
      
      // 🔧 개선: 이미 @MainActor 컨텍스트이므로 Task 불필요
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak blackDomeEntity] in
        guard let entity = blackDomeEntity else {
          print("⚠️ SkyDome 엔티티가 이미 해제됨")
          return
        }
        
        entity.removeFromParent()
        print("✅ SkyDome 제거 완료")
      }
    } else {
      print("❌ SkyDome 엔티티를 찾을 수 없음")
    }

    
    anchor.addChild(roomEntity)
  }
  
  // MARK: - Test Objects
  
  private func loadObject(into anchor: AnchorEntity) async {
    guard
      let clipBoard = try? await ModelEntity(
        named: "Clipboard"
      )
    else {
      print("클립보드 불러오기 실패")
      return
    }
    
    clipBoard.position = SIMD3<Float>(1.04585, 0.85956, 1.1323)
    
    setDragEntity(clipBoard, name: "Clipboard")
    
    anchor.addChild(clipBoard)
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
  
  // MARK: - Entity Setup Methods
  
  private func setDragEntity(_ entity: Entity, name: String) {
    entity.components.set(DraggableComponent())
    entity.components.set(InputTargetComponent())
    
    let physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: .default,
      mode: .dynamic
    )
    entity.components.set(physicsBody)
    entity.generateCollisionShapes(recursive: true)
    
    print("오브젝트 Drag + 물리 속성 설정 완료.")
  }
  
  private func fixedPhysicsBody(_ entity: Entity) {
    let physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: .default,
      mode: .dynamic
    )
    entity.components.set(physicsBody)
    entity.generateCollisionShapes(recursive: true)
    print("환풍구 물리 설정 완료")
  }
  
  private func setUpLockEntity(in boxEntity: Entity) {
    if let lock = boxEntity.findEntity(named: "Plane_008") {
      lock.components.set(InputTargetComponent())
      lock.generateCollisionShapes(recursive: true)
      
      print("Lock에 인터렉션 설정 완료")
    } else {
      print("Lock에 인터렉션 설정 실패")
    }
  }
  
  private func setUpDoorEntity(in doorEntity: Entity) {
    if let knob = doorEntity.findEntity(named: "J_2b17_001") {
      knob.components.set(InputTargetComponent())
      knob.generateCollisionShapes(recursive: true)
      
      print("문고리에 인터렉션 설정 완료")
    } else {
      print("문고리에 인터렉션 설정 실패")
    }
  }
  
  private func setUpDrawerEntity(in drawerEntity: Entity) {
    if let drawer = drawerEntity.findEntity(named: "Cube_007") {
      drawer.components.set(InputTargetComponent())
      drawer.generateCollisionShapes(recursive: true)
      
      print("문고리에 인터렉션 설정 완료")
    } else {
      print("문고리에 인터렉션 설정 실패")
    }
  }
  
  private func setUpKnobEntity(in knobEntity: Entity) {
    if let knob = knobEntity.findEntity(named: "Sphere_004") {
      knob.components.set(InputTargetComponent())
      knob.generateCollisionShapes(recursive: true)
      
      print("문고리에 인터렉션 설정 완료")
    } else {
      print("문고리에 인터렉션 설정 실패")
    }
  }
  
  private func setUpMonitorEntity(in machineEntity: Entity) {
    if let lock = machineEntity.findEntity(named: "Cube_008") {
      lock.components.set(InputTargetComponent())
      lock.generateCollisionShapes(recursive: true)
      
      print("모니터에 인터렉션 설정 완료")
    } else {
      print("모니터에 인터렉션 설정 실패")
    }
  }
  
  private func setUpFileEntity(in boxEntity: Entity) {
    if let lock = boxEntity.findEntity(named: "__pastas_02_001") {
      lock.components.set(InputTargetComponent())
      lock.generateCollisionShapes(recursive: true)
      
      print("File에 인터렉션 설정 완료")
    } else {
      print("File에 인터렉션 설정 실패")
    }
  }
  
  private func setUpVentEntity(in ventEntity: Entity) {
    if let ventgrill = ventEntity.findEntity(named: "AirVent3") {
      ventgrill.components.set(InputTargetComponent())
      ventgrill.generateCollisionShapes(recursive: true)
      
      print("환풍구에 인터렉션 설정 완료")
    } else {
      print("환풍구에 인터렉션 설정 실패")
    }
  }
  
  private func openBox() {
    guard let boxEntity = rootEntity.children.first?.children.first?.findEntity(named: "Box") else {
      print("애니메이션 부모 엔티티 Box 찾기 실패")
      return
    }
    if let openKeypad = boxEntity.findEntity(named: "Plane_008"),
       let openLid = boxEntity.findEntity(named: "Plane_002") {
      print("뚜껑 키패드 둘다 찾음")
      openKeypad.applyTapForBehaviors()
      openLid.applyTapForBehaviors()
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
        self.isPresented = true
      }
    }
  }
  
  func openVent() {
    guard let ventEntity = rootEntity.children.first?.children.first?.findEntity(named: "AirVent3_only") else {
      print("애니메이션 부모 엔티티 AirVent3 찾기 실패")
      return
    }
    if let openAirVent = ventEntity.findEntity(named: "AirVent3") {
      print("환풍구 그릴 찾음")
      openAirVent.applyTapForBehaviors()
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        self.fixedPhysicsBody(openAirVent)
      }
    } else {
      print("환풍구 그릴 못찾음")
    }
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
  
  private func openDrawer() {
    guard let drawerEntity = rootEntity.children.first?.children.first?.findEntity(named: "Desk") else {
      print("Desk 애니메이션 부모 계층 찾기 실패")
      return
    }
    if let openKeypad = drawerEntity.findEntity(named: "Cube_007"),
       let openLid = drawerEntity.findEntity(named: "Sphere_004") {
      print("서랍, 손잡이 둘다 찾음")
      openKeypad.applyTapForBehaviors()
      openLid.applyTapForBehaviors()
    } else {
      print("서랍 손잡이 못찾음")
    }
  }
  
  func fadeSkyDome(duration: Float = 3.0, completion: (() -> Void)? = nil) {
    guard let skyDome = rootEntity.children.first?.findEntity(named: "SkyDome"),
            var opacityComponent = skyDome.components[OpacityComponent.self] else {
          print("❌ SkyDome 또는 OpacityComponent를 찾을 수 없습니다.")
          return
      }
      
      let startTime = Date()
      let targetDuration = TimeInterval(duration)
      let startOpacity = opacityComponent.opacity
      
      let timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
          let elapsed = Date().timeIntervalSince(startTime)
          let progress = min(elapsed / targetDuration, 1.0)
          
          let currentOpacity = startOpacity * (1.0 - Float(progress))
          opacityComponent.opacity = currentOpacity
          skyDome.components.set(opacityComponent)
          
          if progress >= 1.0 {
              timer.invalidate()
              print("✅ SkyDome 페이드아웃 완료!")
              completion?()
          }
      }
      
      RunLoop.current.add(timer, forMode: .common)
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
