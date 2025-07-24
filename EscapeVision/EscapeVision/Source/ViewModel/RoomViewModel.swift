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
  }
  // MARK: - 씬 불러오는 로직
  private func loadRoom(into anchor: AnchorEntity) async {
    // 전체 씬 불러오기
    guard
      let roomEntity = try? await Entity(
        named: "Test3",
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

    if let machineTest = roomEntity.findEntity(named: "Machine_Test_v02") {
      setUpMonitorEntity(in: machineTest)
      print("모니터 설정 성공")
    } else {
      print("모니터 설정 실패")
    }

    if let particleEntity = roomEntity.findEntity(named: "Fog_Emitter_1") {
      particleManager.setParticleEntity(particleEntity)
//      particleEntity.isEnabled = true
      print("✅ RoomViewModel: Particle entity 설정 완료")

      // 디버깅용
      particleManager.debugParticleInfo()
    } else {
      print("❌ RoomViewModel: Fog_Particle_1을 찾을 수 없음")
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

  private func setUpMonitorEntity(in machineEntity: Entity) {
    if let lock = machineEntity.findEntity(named: "Cube_005") {
      lock.components.set(InputTargetComponent())
      lock.generateCollisionShapes(recursive: true)

      print("모니터에 인터렉션 설정 완료")
    } else {
      print("모니터에 인터렉션 설정 실패")
    }
  }

  func playOpenLidAnimation() {
    guard let roomEntity = rootEntity.children.first?.children.first,
      let box = roomEntity.findEntity(named: "Box")
    else {
      print("애니메이션 Box 찾을 수 없음")
      return
    }
    print("사용 가능한 애니메이션들:")
    for animation in box.availableAnimations {
      print("\(animation.name ?? "이름없음")")
    }

    if let lid = box.findEntity(named: "Lid") {
      print("Lid 애니메이션 개수 : \(lid.availableAnimations.count)")
      if let openAnimation = lid.availableAnimations.first(where: {
        $0.name == "OpenLid"
      }) {
        lid.playAnimation(openAnimation)
      }
    } else {
      print("뚜껑 못찾음")
    }

    //    if let openAnimation = lid.availableAnimations.first(where: { $0.name == "OpenLid" }) {
    //      lid.playAnimation(openAnimation)
    //    } else {
    //      print("애니메이션을 찾을 수 없습니다")
    //    }
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
