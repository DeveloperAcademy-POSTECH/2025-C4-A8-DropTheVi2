//
//  RoomViewModel.swift
//  EscapeTest
//
//  Created by 조재훈 on 7/13/25.
//

import Foundation
import RealityKit
import RealityKitContent
import SwiftUI

@MainActor
@Observable
final class RoomViewModel {
  static let shared = RoomViewModel()
  
  private init() {}
  
  var rootEntity = Entity()
  var isPresented: Bool = false
  
  private var worldAnchor: AnchorEntity?
  
  private var particleManager = ParticleManager.shared
  
  // MARK: - 동일한 Anchor 설정을 위한 로직 + 뷰에서 비동기적 처리
  func setup() async {
    let anchor = AnchorEntity(world: matrix_identity_float4x4)
    self.worldAnchor = anchor
    rootEntity.addChild(anchor)
    
    await loadRoom(into: anchor)
    await loadObject(into: anchor)
    
    print("RoomViewModel anchor 설정 성공")
    
    NotificationCenter.default.addObserver(forName: Notification.Name("openBox"), object: nil, queue: .main) { _ in
      print("박스 알림 수신")
      self.openBox()
    }
    NotificationCenter.default.addObserver(forName: Notification.Name("openDrawer"), object: nil, queue: .main) { _ in
      print("서랍 알림 수신")
      self.openDrawer()
    }
  }
  // MARK: - 씬 불러오는 로직
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
    
    if let machineTest = roomEntity.findEntity(named: "Machine_v05") {
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
    
    anchor.addChild(roomEntity)
  }
  
  // MARK: - 테스트 오브젝트
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
  
  func getAnchor() -> AnchorEntity? {
    return self.worldAnchor
  }
  
  // MARK: - 재사용 가능한 인터렉션 설정 함수 (드래그만)
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
  // MARK: - 재사용 가능한 물리 속성 부여 함수 (고정)
  private func fixedPhysicsBody(_ entity: Entity) {
    let physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: .default,
      mode: .static
    )
    entity.components.set(physicsBody)
    entity.generateCollisionShapes(recursive: true)
  }
  // MARK: - 상자를 열기 위해 box엔티티에서 자식계층 찾아서 인터렉션 부여
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
    if let lock = machineEntity.findEntity(named: "Cube_007") {
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
    } else {
      print("뚜껑 못찾음")
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
