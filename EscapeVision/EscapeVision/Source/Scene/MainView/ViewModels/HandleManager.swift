//
//  HandleManager.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation  // 오디오 재생을 위해 추가

@MainActor
@Observable
// swiftlint:disable:next type_body_length
final class HandleManager {
  static let shared = HandleManager()
  
  private let animationManager = HandleAnimationManager.shared
  private let entitySearchManager = EntitySearchManager.shared
  private let handleDetectionManager: HandleDetectionManager
  
  /// 분리된 핸들 엔티티 (HandleDetached)
  private var handleDetached: Entity?
  
  // 오디오 플레이어 (switch_enter 사운드용)
  private var audioPlayer: AVAudioPlayer?
  
  /// Switch1과 HandleDetached 간 거리 임계값 (30cm)
  private let attachmentDistance: Float = 0.3
  
  private init() {
    self.handleDetectionManager = HandleDetectionManager(entitySearchManager: entitySearchManager)
    
    // Switch1 연결 사운드 미리 로딩 (첫 번째 연결 지연 방지)
    preloadSwitchEnterSound()
  }
  
  /// Switch_enter 사운드를 미리 로딩하여 첫 번째 연결 지연 방지
  private func preloadSwitchEnterSound() {
    guard let soundPath = Bundle.main.path(forResource: "09. switch_enter", ofType: "mp3") else {
      print("❌ [오디오 미리로딩] 09. switch_enter.mp3 파일을 찾을 수 없음")
      return
    }
    
    do {
      let soundURL = URL(fileURLWithPath: soundPath)
      audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
      audioPlayer?.volume = 0.8
      audioPlayer?.prepareToPlay()  // 미리 로딩
      print("✅ [오디오 미리로딩] switch_enter 사운드 로딩 완료 - 즉시 재생 준비됨")
    } catch {
      print("❌ [오디오 미리로딩] switch_enter 사운드 로딩 실패: \(error)")
    }
  }
  
  /// Switch1 연결 시 switch_enter 사운드 재생 (미리 로딩된 플레이어 사용)
  private func playSwitchEnterSound() {
    guard let player = audioPlayer else {
      print("❌ [오디오] 미리 로딩된 오디오 플레이어가 없음")
      return
    }
    
    // 이미 재생 중이면 처음부터 다시 재생
    if player.isPlaying {
      player.stop()
      player.currentTime = 0
    }
    
    player.play()
    print("🔊 [오디오] switch_enter 사운드 즉시 재생 (미리 로딩됨)")
  }
  
  /// Handle1을 Switch에서 완전히 제거
  func removeHandle1FromSwitch(switchIndex: Int, from rootEntity: Entity) async {
    print("🗑️ Switch\(switchIndex) Handle1 제거 시작")
    
    guard let roomEntity = entitySearchManager.findRoomEntity(from: rootEntity) else {
      print("❌ Room 엔티티 찾기 실패")
      return
    }
    
    guard let switchEntity = entitySearchManager.findSwitchEntity(in: roomEntity, switchNumber: switchIndex) else {
      print("❌ Switch\(switchIndex) 엔티티 찾기 실패")
      return
    }
    
    guard let handleEntity = entitySearchManager.findHandleEntity(in: switchEntity, handleNumber: 1) else {
      print("❌ Switch\(switchIndex) Handle1 엔티티 찾기 실패")
      return
    }
    
    handleEntity.removeFromParent()
    print("✅ Switch\(switchIndex) Handle1 제거 완료: \(handleEntity.name)")
  }
  
  /// Switch1에 분리된 핸들 설정
  func setupSwitch1WithDetachedHandle(from rootEntity: Entity, worldAnchor: Entity) async {
    print("🔧 Switch1 Handle1 숨김 및 HandleDetached 설정 시작")
    
    guard let roomEntity = entitySearchManager.findRoomEntity(from: rootEntity) else {
      print("❌ Room 엔티티 찾기 실패")
      return
    }
    
    guard let switch1Entity = entitySearchManager.findSwitchEntity(in: roomEntity, switchNumber: 1) else {
      print("❌ Switch1 엔티티 찾기 실패")
      return
    }
    
    guard let handle1Entity = entitySearchManager.findHandleEntity(in: switch1Entity, handleNumber: 1) else {
      print("❌ Switch1 Handle1 엔티티 찾기 실패") 
      return
    }
    
    // Switch1 Handle1 완전히 제거 (중복 방지)
    handle1Entity.removeFromParent()
    print("🗑️ Switch1 Handle1 완전히 제거: \(handle1Entity.name)")
    
    // HandleDetached 설정
    if let detachedEntity = await handleDetectionManager.findAndSetupHandleDetached(from: rootEntity) {
      setupHandleDetachedComponents(detachedEntity)
      handleDetached = detachedEntity
    }
    
    print("✅ Switch1 Handle1 숨김 및 HandleDetached 설정 완료")
  }
  
  /// HandleDetached 컴포넌트 설정
  private func setupHandleDetachedComponents(_ entity: Entity) {
    print("🔧 컴포넌트 설정: \(entity.name), 위치: \(entity.position)")
    
    entity.components.set(DraggableComponent())
    entity.components.set(InputTargetComponent())
    entity.components.set(HandleComponent(switchIndex: 1, isAttached: false, isBeingDragged: false))
    
    let handleBounds = entity.visualBounds(relativeTo: nil)
    let handleSize = handleBounds.max - handleBounds.min
    
    print("  크기: \(handleSize)")
    
    let safeHandleSize = SIMD3<Float>(
      handleSize.x < 0.01 ? 0.03 : handleSize.x,
      handleSize.y < 0.01 ? 0.03 : handleSize.y,
      handleSize.z < 0.01 ? 0.03 : handleSize.z
    )
    
    let expandedCollisionSize = SIMD3<Float>(
      max(0.06, safeHandleSize.x * 1.2),  // 20% 확장, 최소 6cm
      max(0.06, safeHandleSize.y * 1.2),  // 20% 확장, 최소 6cm
      max(0.06, safeHandleSize.z * 1.2)   // 20% 확장, 최소 6cm
    )
    
    print("  충돌 크기: \(expandedCollisionSize)")
    
    let collisionShape = ShapeResource.generateBox(size: expandedCollisionSize)
    entity.components.set(CollisionComponent(shapes: [collisionShape], mode: .default, filter: .init(group: .default, mask: .all)))
    
    // createBlueTransparentIndicator(for: entity, size: expandedCollisionSize) // 더미 표시 제거
    
    let physicsBody = PhysicsBodyComponent(
      massProperties: PhysicsMassProperties(mass: 0.1),
      material: PhysicsMaterialResource.generate(staticFriction: 0.8, dynamicFriction: 0.6, restitution: 0.1),
      mode: .kinematic
    )
    entity.components.set(physicsBody)
    
    print("✅ 컴포넌트 설정 완료")
  }
  
  /// 기존 파란색 표시 제거
  func removeBlueIndicators(from rootEntity: Entity) {
    func removeIndicatorsRecursively(from entity: Entity) {
      // 현재 엔티티에서 파란색 표시 제거
      if let blueIndicator = entity.findEntity(named: "BlueCollisionIndicator") {
        blueIndicator.removeFromParent()
        print("🗑️ 파란색 더미 표시 제거: \(entity.name)")
      }
      if let debugIndicator = entity.findEntity(named: "DebugCollisionIndicator") {
        debugIndicator.removeFromParent()
        print("🗑️ 빨간 더미 표시 제거: \(entity.name)")
      }
      
      // 자식 엔티티들에서 재귀적으로 제거
      for child in entity.children {
        removeIndicatorsRecursively(from: child)
      }
    }
    
    removeIndicatorsRecursively(from: rootEntity)
    print("✅ 모든 더미 표시 제거 완료")
  }

  /// 파란색 투명 시각적 표시 생성
  private func createBlueTransparentIndicator(for parentEntity: Entity, size: SIMD3<Float>) {
    print("🔵 파란색 박스 생성: \(parentEntity.name)")
    print("  부모 위치: \(parentEntity.position)")
    
    if let existingIndicator = parentEntity.findEntity(named: "BlueCollisionIndicator") {
      existingIndicator.removeFromParent()
    }
    
    var blueMaterial = SimpleMaterial()
    blueMaterial.color = .init(tint: UIColor.cyan.withAlphaComponent(0.7), texture: nil)
    blueMaterial.metallic = 0.0
    blueMaterial.roughness = 0.5
    
    let indicatorBox = ModelEntity(
      mesh: .generateBox(size: size), 
      materials: [blueMaterial]
    )
    indicatorBox.name = "BlueCollisionIndicator"
    indicatorBox.position = SIMD3<Float>(0, 0, 0)
    
    indicatorBox.components.remove(PhysicsBodyComponent.self)
    indicatorBox.components.remove(CollisionComponent.self)
    
    parentEntity.addChild(indicatorBox)
    
    let worldPosition = indicatorBox.convert(position: indicatorBox.position, to: nil)
    print("  박스 월드 위치: \(worldPosition)")
    
    let totalVolume = size.x * size.y * size.z
    if totalVolume < 0.001 {
      var debugMaterial = SimpleMaterial()
      debugMaterial.color = .init(tint: UIColor.red.withAlphaComponent(0.8), texture: nil)
      
      let debugBox = ModelEntity(
        mesh: .generateBox(size: SIMD3<Float>(0.2, 0.2, 0.2)), 
        materials: [debugMaterial]
      )
      debugBox.name = "DebugCollisionIndicator"
      debugBox.position = SIMD3<Float>(0, 0.1, 0)
      
      debugBox.components.remove(PhysicsBodyComponent.self)
      debugBox.components.remove(CollisionComponent.self)
      
      parentEntity.addChild(debugBox)
      print("🔴 빨간 디버그 박스 추가")
    }
    
    print("✅ 파란색 박스 완료")
  }
  
  // MARK: - Missing Methods (added back for compatibility)
  
  /// HandleDetached 엔티티 반환
  func getHandleDetached() -> Entity? {
    return handleDetached
  }
  
  /// 핸들과 스위치 간의 오버랩 확인
  func checkHandleOverlap(handle: Entity, from rootEntity: Entity) -> Bool {
    // 기본적으로 false 반환 (추후 구현 필요시 확장)
    return false
  }
  
  /// 핸들을 스위치에 끼우기
  func attachHandleToSwitch(handle: Entity, from rootEntity: Entity) {
    // 기본 구현 (추후 필요시 확장)
    print("attachHandleToSwitch 호출됨")
  }
  
  /// 핸들이 끼워져 있는지 확인
  func isHandleAttached(switchIndex: Int) -> Bool {
    // 기본적으로 false 반환 (추후 구현 필요시 확장)
    return false
  }
  
  /// 분리된 핸들 가져오기
  func getDetachedHandle(switchIndex: Int) -> Entity? {
    // 기본적으로 nil 반환 (추후 구현 필요시 확장)
    return nil
  }
  
  /// HandleDetached를 Switch1에 부착 (Handle1으로 변환)
  func attachHandleDetachedToSwitch1(from rootEntity: Entity) {
    print("🔗 [Handle 부착] HandleDetached를 Switch1에 연결 시작")
    
    // HandleDetached 숨기기
    if let handleDetached = getHandleDetached() {
      handleDetached.isEnabled = false
      // HandleDetached를 완전히 제거하여 더 이상 상호작용하지 않도록 함
      handleDetached.removeFromParent()
      print("👻 [Handle 부착] HandleDetached 숨김 및 제거 처리")
    }
    
    // Handle1을 Switch1에 복원
    restoreHandle1ToSwitch1()
    
    // Switch1 연결 성공 사운드 재생
    playSwitchEnterSound()
    
    print("✅ [Handle 부착] Switch1 Handle1이 벽에 수직방향으로 복원되었습니다")
    print("🎯 [HandleDetached 종료] 사용자가 Switch1 근처에 놓아서 연결됨")
  }
  
  /// Switch1이 활성화되었는지 확인
  func getSwitch1ActivationStatus() -> Bool {
    // 기본적으로 false 반환 (추후 구현 필요시 확장)
    return false
  }
  
  /// HandleDetached와 Switch1의 근접 확인 (드래그 종료 시점에만 호출)
  func checkHandleDetachedProximityToSwitch1(from rootEntity: Entity) -> Bool {
    guard let handleDetached = getHandleDetached() else {
      print("❌ [근접 체크] HandleDetached 엔티티가 없음")
      return false
    }
    
    guard let roomEntity = entitySearchManager.findRoomEntity(from: rootEntity) else {
      print("❌ [근접 체크] Room 엔티티 찾기 실패")
      return false
    }
    
    guard let switch1Entity = entitySearchManager.findSwitchEntity(in: roomEntity, switchNumber: 1) else {
      print("❌ [근접 체크] Switch1 엔티티 찾기 실패")  
      return false
    }
    
    // HandleDetached 위치
    let handlePosition = handleDetached.convert(position: .zero, to: nil)
    
    // Switch1의 실제 Joint 위치 찾기
    var switch1Position = SIMD3<Float>(-1.97, 0.17, 0.77) // 기본값
    
    // Switch1에서 Joint 직접 찾기
    if let joint1 = findJointInSwitch1(switch1Entity) {
      let jointPos = joint1.convert(position: .zero, to: nil)
      if length(jointPos) > 0.1 { // 원점이 아니면
        switch1Position = jointPos
        print("🎯 [Switch1 Joint 발견] 실제 위치: \(String(format: "%.3f,%.3f,%.3f", jointPos.x, jointPos.y, jointPos.z))")
      }
    } else {
      // Switch2의 Joint 위치를 기반으로 Switch1 추정
      if let switch2Entity = entitySearchManager.findSwitchEntity(in: roomEntity, switchNumber: 2),
         let joint2 = findJointInSwitch1(switch2Entity) {
        let joint2Pos = joint2.convert(position: .zero, to: nil)
        // Switch1은 Switch2보다 Z축으로 +0.21만큼 앞에 있다고 가정
        switch1Position = SIMD3<Float>(joint2Pos.x, joint2Pos.y, joint2Pos.z + 0.21)
        print("🧮 [Switch1 추정] Switch2 기반: \(String(format: "%.3f,%.3f,%.3f", switch1Position.x, switch1Position.y, switch1Position.z))")
      }
    }
    
    let distance = length(handlePosition - switch1Position)
    
    // 부착 거리를 30cm로 확대 (더 관대하게)
    let attachmentThreshold: Float = 0.30
    
    print("🔍 [근접 체크 v3] ================")
    print("  HandleDetached 위치: \(String(format: "%.3f,%.3f,%.3f", handlePosition.x, handlePosition.y, handlePosition.z))")
    print("  Switch1 실제 위치: \(String(format: "%.3f,%.3f,%.3f", switch1Position.x, switch1Position.y, switch1Position.z))")
    print("  실제 거리: \(String(format: "%.3f", distance))m")
    print("  임계값: \(String(format: "%.3f", attachmentThreshold))m")
    print("  차이: \(String(format: "%.3f", distance - attachmentThreshold))m")
    
    // 3D 벡터 분석
    let deltaVector = handlePosition - switch1Position
    print("🔍 [3D 거리 분석]")
    print("  X축 차이: \(String(format: "%.3f", abs(deltaVector.x)))m (\(String(format: "%.1f", abs(deltaVector.x) * 100))cm)")
    print("  Y축 차이: \(String(format: "%.3f", abs(deltaVector.y)))m (\(String(format: "%.1f", abs(deltaVector.y) * 100))cm)")
    print("  Z축 차이: \(String(format: "%.3f", abs(deltaVector.z)))m (\(String(format: "%.1f", abs(deltaVector.z) * 100))cm)")
    
    if distance <= attachmentThreshold {
      print("✅ [근접 체크] Switch1과 충분히 가까움 - 연결 진행!")
      print("🎯 [성공!] \(String(format: "%.1f", (attachmentThreshold - distance) * 100))cm 여유로 성공")
      return true
    } else {
      print("❌ [근접 체크] Switch1과 너무 멀음 - 연결 불가")
      print("  📏 필요한 거리: \(String(format: "%.1f", (distance - attachmentThreshold) * 100))cm 더 가까이")
      
      // 가까워질수록 격려 메시지
      if distance <= 0.35 {
        print("🔥 [거의 다 왔어요!] 조금만 더 가까이!")
      } else if distance <= 0.50 {
        print("💪 [좋은 진전!] 절반 이상 왔습니다!")
      }
      
      return false
    }
  }
  
  /// Switch1에서 Joint 찾기
  private func findJointInSwitch1(_ switchEntity: Entity) -> Entity? {
    for child in switchEntity.children {
      if child.name.lowercased().contains("joint") {
        return child
      }
      // 재귀적으로 찾기
      for grandchild in child.children {
        if grandchild.name.lowercased().contains("joint") {
          return grandchild
        }
      }
    }
    return nil
  }
  
  /// Switch1에 Handle1을 복원하고 HandleDetached 숨기기 (벽에 수직방향 배치)
  func restoreHandle1ToSwitch1() {
    print("🔄 [Handle 복원] Switch1 Handle1 복원 시작")
    
    guard let roomEntity = entitySearchManager.findRoomEntity(from: RoomViewModel.shared.rootEntity) else {
      print("❌ [Handle 복원] Room 엔티티 찾기 실패")
      return
    }
    
    guard let switchEntity = entitySearchManager.findSwitchEntity(in: roomEntity, switchNumber: 1) else {
      print("❌ [Handle 복원] Switch1 엔티티 찾기 실패")
      return
    }
    
    print("✅ [Handle 복원] Switch1 엔티티 발견: \(switchEntity.name)")
    print("📍 [Handle 복원] Switch1 위치: \(String(format: "%.3f,%.3f,%.3f", switchEntity.position.x, switchEntity.position.y, switchEntity.position.z))")
    
    // Switch1에 SwitchComponent 추가 (토글 기능을 위해 필수)
    if !switchEntity.components.has(SwitchComponent.self) {
      switchEntity.components.set(SwitchComponent(switchIndex: 1, handleCount: 1))
      print("🔧 [컴포넌트] Switch1에 SwitchComponent 추가 완료")
    } else {
      print("✅ [컴포넌트] Switch1에 SwitchComponent 이미 존재")
    }
    
    // HandleDetached 숨기기
    if let handleDetached = getHandleDetached() {
      handleDetached.isEnabled = false
      // HandleDetached를 완전히 제거하여 더 이상 상호작용하지 않도록 함
      handleDetached.removeFromParent()
      print("👻 [Handle 복원] HandleDetached 숨김 및 제거 처리 완료")
    }
    
    // Handle1이 이미 존재하는지 확인
    let existingHandle1 = entitySearchManager.findHandleEntity(in: switchEntity, handleNumber: 1)
    
    let finalHandle1: Entity
    
    if let existing = existingHandle1 {
      print("✅ [Handle 발견] 기존 Handle1 사용: \(existing.name)")
      finalHandle1 = existing
    } else {
      print("🆕 [Handle 생성] 새로운 Handle1 생성 중...")
      
      // HandleDetached로부터 새로운 Handle1 생성
      guard let handleDetached = getHandleDetached() else {
        print("❌ [Handle 복원] HandleDetached를 찾을 수 없음")
        return
      }
      
      guard let handle1 = createHandle1FromHandleDetached(handleDetached, in: switchEntity) else {
        print("❌ [Handle 복원] Handle1 생성 실패")
        return
      }
      
      finalHandle1 = handle1
    }
    
    // 부모 관계 및 SwitchComponent 검증
    print("🔍 [부모 검증] Handle1 부모 체인 확인:")
    print("  - Handle1 부모: \(finalHandle1.parent?.name ?? "nil")")
    print("  - Switch1 이름: \(switchEntity.name)")
    
    // Handle1이 Switch1의 자식이 아니라면 강제로 다시 부착
    if finalHandle1.parent != switchEntity {
      print("⚠️ [부모 수정] Handle1이 Switch1의 자식이 아님! 강제로 재부착")
      finalHandle1.removeFromParent() // 기존 부모에서 제거
      switchEntity.addChild(finalHandle1) // Switch1에 재부착
      print("✅ [부모 수정] Handle1을 Switch1에 강제 재부착 완료")
    }
    
    var currentParent = finalHandle1.parent
    var parentChain = finalHandle1.name
    while let parent = currentParent {
      parentChain += " → \(parent.name)"
      if let switchComp = parent.components[SwitchComponent.self] {
        print("🔍 [부모 체인 검증] \(parent.name) - SwitchComponent: ✅ (인덱스: \(switchComp.switchIndex))")
      } else {
        print("🔍 [부모 체인 검증] \(parent.name) - SwitchComponent: ❌")
      }
      currentParent = parent.parent
    }
    print("🔗 [전체 부모 체인] \(parentChain)")
    
    // Switch1에 SwitchComponent 확인/추가
    if !switchEntity.components.has(SwitchComponent.self) {
      switchEntity.components.set(SwitchComponent(switchIndex: 1, handleCount: 1))
      print("🔧 [컴포넌트] Switch1에 SwitchComponent 추가 완료")
    } else {
      print("✅ [컴포넌트] Switch1에 SwitchComponent 이미 존재")
      if let switchComp = switchEntity.components[SwitchComponent.self] {
        print("  - 현재 Switch 인덱스: \(switchComp.switchIndex)")
        
        // Switch 인덱스가 1이 아니라면 강제로 수정
        if switchComp.switchIndex != 1 {
          print("⚠️ [컴포넌트 수정] Switch1의 인덱스가 \(switchComp.switchIndex)! 1로 수정")
          switchEntity.components.set(SwitchComponent(switchIndex: 1, handleCount: 1))
          print("✅ [컴포넌트 수정] Switch1 인덱스를 1로 강제 수정 완료")
        }
      }
    }
    
    // Handle1의 HandleComponent 확인 및 수정
    if let handleComp = finalHandle1.components[HandleComponent.self] {
      print("🔍 [Handle 컴포넌트] 현재 switchIndex: \(handleComp.switchIndex)")
      if handleComp.switchIndex != 1 {
        print("⚠️ [Handle 컴포넌트 수정] switchIndex가 \(handleComp.switchIndex)! 1로 수정")
        finalHandle1.components.set(HandleComponent(switchIndex: 1, isAttached: true, isBeingDragged: false))
        print("✅ [Handle 컴포넌트 수정] Handle1 switchIndex를 1로 강제 수정 완료")
      }
    } else {
      print("⚠️ [Handle 컴포넌트] HandleComponent 없음! 추가")
      finalHandle1.components.set(HandleComponent(switchIndex: 1, isAttached: true, isBeingDragged: false))
      print("✅ [Handle 컴포넌트] HandleComponent 추가 완료")
    }
    
    // 토글 기능 설정 (SwitchManager 등록) - 통일된 메서드 사용
    setupHandle1ForToggling(finalHandle1, in: switchEntity)
    
    // Handle1 활성화
    finalHandle1.isEnabled = true
    
    // 최종 확인
    print("🎯 [최종 확인] Handle1 설정 상태:")
    print("  - Handle1 부모: \(finalHandle1.parent?.name ?? "nil")")
    print("  - Switch1 SwitchComponent 인덱스: \(switchEntity.components[SwitchComponent.self]?.switchIndex ?? -1)")
    print("  - Handle1 HandleComponent 인덱스: \(finalHandle1.components[HandleComponent.self]?.switchIndex ?? -1)")
    
    print("✅ [Handle 복원] Switch1 Handle1이 벽에 수직방향으로 활성화되고 토글 가능합니다")
  }
  
  /// HandleDetached로부터 Handle1을 생성하고 Switch1에 부착
  private func createHandle1FromHandleDetached(_ handleDetached: Entity, in switchEntity: Entity) -> Entity? {
    print("🆕 [Handle 생성] HandleDetached로부터 Handle1 생성 시작")
    
    // HandleDetached를 복제하여 Handle1 생성
    let handle1 = handleDetached.clone(recursive: true)
    handle1.name = "Handle1" // 명확한 이름 설정
    
    print("📋 [Handle 생성] 복사된 Handle1 기본 정보:")
    print("  - 이름: \(handle1.name)")
    print("  - 타입: \(type(of: handle1))")
    print("  - children: \(handle1.children.count)개")
    
    // Switch1에서 Joint1 찾기
    guard let joint1 = findJointInSwitch1(switchEntity) else {
      print("❌ [Handle 생성] Joint1을 찾을 수 없음")
      return nil
    }
    
    print("🔗 [Joint 발견] 이름: '\(joint1.name)' - 엔티티: \(joint1.name)")
    
    // Joint1의 월드 위치 가져오기
    let jointWorldPosition = joint1.convert(position: .zero, to: nil)
    
    // Handle1을 Joint1과 동일한 위치에 배치 (옆이 아니라 정확히 중심에)
    let handlePosition = jointWorldPosition // 오프셋 제거
    
    // Switch2와 반대 모양으로 y축 +15도 회전 설정
    let yAxisRotation = simd_quatf(angle: 0.262, axis: [0, 1, 0]) // y축 +15도 (0.262 라디안)
    handle1.position = handlePosition
    handle1.orientation = yAxisRotation
    
    print("📍 [Handle 생성] 정확한 Joint1 중심 위치 설정: \(String(format: "%.3f,%.3f,%.3f", handlePosition.x, handlePosition.y, handlePosition.z))")
    print("🔄 [Handle 회전] Switch2와 반대 모양 - y축 +15도 회전 적용: \(yAxisRotation)")
    
    // Handle1을 Switch1에 부착
    switchEntity.addChild(handle1)
    print("🔗 [부착 완료] Handle1이 Switch1에 부착됨")
    print("  - Handle1 부모: \(handle1.parent?.name ?? "nil")")
    print("  - Switch1 이름: \(switchEntity.name)")
    print("  - Switch1의 SwitchComponent: \(switchEntity.components.has(SwitchComponent.self))")
    
    // 부모 체인 검증
    var currentParent = handle1.parent
    var parentChain = handle1.name
    while let parent = currentParent {
      parentChain += " → \(parent.name)"
      let hasSwitchComponent = parent.components.has(SwitchComponent.self)
      if let switchComp = parent.components[SwitchComponent.self] {
        print("🔍 [부모 체인] \(parent.name) - SwitchComponent: ✅ (인덱스: \(switchComp.switchIndex))")
      } else {
        print("🔍 [부모 체인] \(parent.name) - SwitchComponent: ❌")
      }
      currentParent = parent.parent
    }
    print("🔗 [전체 부모 체인] \(parentChain)")
    
    // Switch1에 SwitchComponent 추가 (토글 기능을 위해 필수)
    if !switchEntity.components.has(SwitchComponent.self) {
      switchEntity.components.set(SwitchComponent(switchIndex: 1, handleCount: 1))
      print("🔧 [컴포넌트] Switch1에 SwitchComponent 추가 완료")
    } else {
      print("✅ [컴포넌트] Switch1에 SwitchComponent 이미 존재")
      if let switchComp = switchEntity.components[SwitchComponent.self] {
        print("  - 현재 Switch 인덱스: \(switchComp.switchIndex)")
      }
    }
    
    // 월드 좌표를 로컬 좌표로 변환하여 설정
    let localPosition = switchEntity.convert(position: handlePosition, from: nil)
    handle1.position = localPosition
    
    // 다른 Switch들과 동일한 방향 설정 (벽에 수직)
    // Switch2의 초기 방향을 SwitchManager에서 가져와서 사용 (토글된 상태가 아닌 초기 상태)
    let switchManager = SwitchManager.shared
    if let switch2InitialOrientation = switchManager.getHandleInitialOrientation(for: 2) {
      handle1.orientation = switch2InitialOrientation
      print("🔄 [Handle 방향] Switch2 초기 방향 사용: \(switch2InitialOrientation)")
      print("   └─ 토글 상태와 무관하게 올바른 초기 방향 적용")
    } else {
      // Switch2 초기 방향이 없으면 현재 방향 사용 (이전 방식)
      if let switch2Entity = entitySearchManager.findSwitchEntity(in: switchEntity.parent!, switchNumber: 2),
         let handle2 = findHandleInSwitch(switch2Entity) {
        let handle2Orientation = handle2.orientation
        handle1.orientation = handle2Orientation
        print("🔄 [Handle 방향] Switch2 현재 방향 사용 (fallback): \(handle2Orientation)")
        print("   ⚠️ Switch2가 토글되었다면 비정상적인 방향일 수 있음")
      } else {
        // 기본 벽 수직 방향 설정
        handle1.orientation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        print("🔄 [Handle 방향] 기본 벽 수직 방향 설정")
      }
    }
    
    // 🎯 토글 기능을 위한 필수 컴포넌트 추가
    
    // 1. HandleComponent 추가 (핸들 식별용) - switchIndex를 반드시 1로 설정
    handle1.components.set(HandleComponent(switchIndex: 1, isAttached: true, isBeingDragged: false))
    print("🔧 [컴포넌트] HandleComponent 추가 완료 - switchIndex: 1")
    
    // HandleComponent 검증
    if let handleComp = handle1.components[HandleComponent.self] {
      print("✅ [HandleComponent 검증] switchIndex: \(handleComp.switchIndex)")
      if handleComp.switchIndex != 1 {
        print("⚠️ [HandleComponent 오류] switchIndex가 \(handleComp.switchIndex)! 다시 설정")
        handle1.components.set(HandleComponent(switchIndex: 1, isAttached: true, isBeingDragged: false))
      }
    }
    
    // 2. InputTargetComponent 추가 (터치/클릭 감지용)
    handle1.components.set(InputTargetComponent(allowedInputTypes: .indirect))
    print("🔧 [컴포넌트] InputTargetComponent 추가 완료")
    
    // 3. CollisionComponent 추가 (충돌 감지용) - 확대된 충돌영역
    let expandedSize = SIMD3<Float>(0.30, 0.30, 0.30)
    let handleShape = ShapeResource.generateBox(size: expandedSize)
    handle1.components.set(CollisionComponent(shapes: [handleShape]))
    print("🔧 [컴포넌트] CollisionComponent 추가 완료 - 확대된 충돌영역: \(expandedSize)")
    print("   └─ 조작 편의성 향상: Handle1 전체 사이즈 커버 (20cm 충돌영역)")
    
    // 4. 물리 효과 추가 (드래그 가능하도록)
    handle1.components.set(PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic))
    print("🔧 [컴포넌트] PhysicsBodyComponent 추가 완료")
    
    // 5. DraggableComponent 추가 (드래그 감지용)
    handle1.components.set(DraggableComponent())
    print("🔧 [컴포넌트] DraggableComponent 추가 완료")
    
    // Handle1 활성화
    handle1.isEnabled = true
    print("✅ [Handle 활성화] Handle1 완전 활성화 및 토글 준비 완료")
    
    // 토글 기능 설정 (SwitchManager 등록)
    setupHandle1ForToggling(handle1, in: switchEntity)
    
    print("✅ [Handle 생성] Handle1 생성 및 부착 완료")
    return handle1
  }
  
  /// Switch에서 Handle 찾기
  private func findHandleInSwitch(_ switchEntity: Entity) -> Entity? {
    for child in switchEntity.children {
      if child.name.lowercased().contains("handle") {
        return child
      }
    }
    return nil
  }
  
  /// Handle1을 토글 가능하도록 설정
  private func setupHandle1ForToggling(_ handle1: Entity, in switchEntity: Entity) {
    print("🎮 [토글 설정] Handle1 토글 기능 설정 시작")
    let switchManager = SwitchManager.shared
    
    // 컴포넌트 확인 (이미 추가되어 있어야 함)
    let hasInputTarget = handle1.components.has(InputTargetComponent.self)
    let hasHandleComponent = handle1.components.has(HandleComponent.self)
    let hasDraggable = handle1.components.has(DraggableComponent.self)
    
    print("🔍 [컴포넌트 체크] InputTarget: \(hasInputTarget), Handle: \(hasHandleComponent), Draggable: \(hasDraggable)")
    
    // 필수 컴포넌트가 없으면 추가
    if !hasInputTarget {
      handle1.components.set(InputTargetComponent(allowedInputTypes: .indirect))
      print("🔧 [추가] InputTargetComponent 추가")
    }
    
    if !hasHandleComponent {
      handle1.components.set(HandleComponent(switchIndex: 1, isAttached: true, isBeingDragged: false))
      print("🔧 [추가] HandleComponent 추가")
    }
    
    if !hasDraggable {
      handle1.components.set(DraggableComponent())
      print("🔧 [추가] DraggableComponent 추가")
    }
    
    // Joint 찾기 - 통일된 로직 사용
    let joint1 = findJointInSwitch1(switchEntity)
    if let joint = joint1 {
      print("🔗 [Joint 발견] Joint1 찾음: \(joint.name) - 위치: \(joint.position)")
    } else {
      print("⚠️ [Joint 경고] Switch1에서 Joint1을 찾을 수 없음")
    }
    
    // SwitchManager에 Handle 정보 등록 (Switch2~5와 동일한 방식)
    // setupHandleForDragging과 registerHandle이 모든 위치 설정을 처리함
    print("🎮 [토글 등록] Handle1을 SwitchManager에 등록 - Switch2~5와 동일한 방식")
    switchManager.registerHandle(handle1, forSwitchIndex: 1, withJoint: joint1)
    print("✅ [토글 등록] Handle1 토글 기능 등록 완료")
    
    print("🎮 [Handle 토글] Handle1 토글 기능 설정 완료")
  }
}
