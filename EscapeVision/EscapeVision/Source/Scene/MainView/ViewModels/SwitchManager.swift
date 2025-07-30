//
//  SwitchManager.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation  // 토글 오디오 재생을 위해 추가
import AudioToolbox  // SystemSoundID 사용을 위해 추가

@MainActor
@Observable
// swiftlint:disable:next type_body_length
final class SwitchManager {
  static let shared = SwitchManager()
  
  // 각 스위치의 Joint 정보 저장
  private var switchJoints: [Int: Entity] = [:]
  
  // 각 핸들의 초기 방향 저장
  private var handleInitialOrientations: [Int: simd_quatf] = [:]
  
  // 각 핸들의 초기 위치 저장
  private var handleInitialPositions: [Int: SIMD3<Float>] = [:]
  
  // 각 스위치의 현재 상태 저장 (실제 시각적 상태: 0=위/+15도, 1=아래/-45도)
  // 초기 상태: 모든 핸들이 위(0) 상태에서 시작
  private var switchStates: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
  
  // 토글 사운드 플레이어 (switch_change 사운드용)
  private var toggleAudioPlayer: AVAudioPlayer?
  
  // SystemSoundID 대안 (더 빠른 재생)
  private var switchChangeSoundID: SystemSoundID = 0
  
  // 특별 상태 사운드 플레이어 (11.mp3 파일용)
  private var specialStateAudioPlayer: AVAudioPlayer?
  
  private let entitySearchManager = EntitySearchManager.shared
  
  private init() {
    print("SwitchManager 초기화")
    
    // 토글 사운드 미리 로딩 (첫 번째 토글 지연 방지)
    preloadSwitchChangeSound()
    
    // SystemSoundID 방식도 준비 (더 확실한 대안)
    setupSystemSound()
    
    // 특별 상태 사운드 미리 로딩 (01100 상태용)
    preloadSpecialStateSound()
  }
  
  deinit {
    // SystemSoundID 리소스 해제 - Main Actor context에서 실행
    Task { @MainActor in
      if switchChangeSoundID != 0 {
        AudioServicesDisposeSystemSoundID(switchChangeSoundID)
        print("🗑️ [SystemSound] SystemSoundID 리소스 해제 완료")
      }
    }
  }
  
  /// Switch_change 사운드를 미리 로딩하여 첫 번째 토글 지연 방지
  private func preloadSwitchChangeSound() {
    // 1. AVAudioSession 설정 (Vision Pro 환경 대응)
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try AVAudioSession.sharedInstance().setActive(true)
      print("✅ [오디오 세션] AVAudioSession 설정 완료")
    } catch {
      print("⚠️ [오디오 세션] AVAudioSession 설정 실패: \(error)")
    }
    
    guard let soundPath = Bundle.main.path(forResource: "10. switch_change", ofType: "mp3") else {
      print("❌ [오디오 미리로딩] 10. switch_change.mp3 파일을 찾을 수 없음")
      return
    }
    
    do {
      let soundURL = URL(fileURLWithPath: soundPath)
      toggleAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
      toggleAudioPlayer?.volume = 0.7
      toggleAudioPlayer?.prepareToPlay()  // 미리 로딩
      
      // 2. 더미 재생으로 완전한 초기화 (무음으로 실제 재생)
      let originalVolume = toggleAudioPlayer?.volume ?? 0.7
      toggleAudioPlayer?.volume = 0.0  // 무음으로 설정
      toggleAudioPlayer?.play()  // 실제로 재생
      
      // 0.1초 후 정지하고 볼륨 복원
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.toggleAudioPlayer?.stop()
        self?.toggleAudioPlayer?.currentTime = 0
        self?.toggleAudioPlayer?.volume = originalVolume  // 원래 볼륨 복원
        print("✅ [오디오 미리로딩] switch_change 사운드 더미 재생 완료 - 즉시 재생 준비됨")
      }
      
    } catch {
      print("❌ [오디오 미리로딩] switch_change 사운드 로딩 실패: \(error)")
    }
  }
  
  /// SystemSoundID 방식으로 사운드 설정 (더 빠른 대안)
  private func setupSystemSound() {
    guard let soundPath = Bundle.main.path(forResource: "10. switch_change", ofType: "mp3") else {
      print("❌ [SystemSound] 10. switch_change.mp3 파일을 찾을 수 없음")
      return
    }
    
    let soundURL = URL(fileURLWithPath: soundPath)
    let status = AudioServicesCreateSystemSoundID(soundURL as CFURL, &switchChangeSoundID)
    
    if status == kAudioServicesNoError {
      print("✅ [SystemSound] switch_change SystemSoundID 생성 완료 - ID: \(switchChangeSoundID)")
    } else {
      print("❌ [SystemSound] switch_change SystemSoundID 생성 실패 - 상태: \(status)")
    }
  }
  
  /// 특별 상태 사운드(11.mp3) 미리 로딩
  private func preloadSpecialStateSound() {
    guard let soundPath = Bundle.main.path(forResource: "11", ofType: "mp3") else {
      print("❌ [특별 상태 오디오] 11.mp3 파일을 찾을 수 없음")
      return
    }
    
    do {
      let soundURL = URL(fileURLWithPath: soundPath)
      specialStateAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
      specialStateAudioPlayer?.volume = 0.8
      specialStateAudioPlayer?.prepareToPlay()
      
      // 더미 재생으로 완전한 초기화
      let originalVolume = specialStateAudioPlayer?.volume ?? 0.8
      specialStateAudioPlayer?.volume = 0.0
      specialStateAudioPlayer?.play()
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.specialStateAudioPlayer?.stop()
        self?.specialStateAudioPlayer?.currentTime = 0
        self?.specialStateAudioPlayer?.volume = originalVolume
        print("✅ [특별 상태 오디오] 11.mp3 사운드 미리 로딩 완료")
      }
      
    } catch {
      print("❌ [특별 상태 오디오] 11.mp3 사운드 로딩 실패: \(error)")
    }
  }
  
  /// Switch 토글 시 switch_change 사운드 재생 (두 가지 방법 시도)
  private func playSwitchChangeSound() {
    // 방법 1: AVAudioPlayer 사용 (기본)
    if let player = toggleAudioPlayer {
      // 이미 재생 중이면 처음부터 다시 재생
      if player.isPlaying {
        player.stop()
        player.currentTime = 0
      }
      
      let success = player.play()
      if success {
        print("🔊 [토글 오디오] switch_change 사운드 재생 성공 (AVAudioPlayer 방식)")
        return
      } else {
        print("⚠️ [토글 오디오] AVAudioPlayer 재생 실패 - SystemSoundID 방식으로 시도")
      }
    }
    
    // 방법 2: SystemSoundID 사용 (대안)
    if switchChangeSoundID != 0 {
      AudioServicesPlaySystemSound(switchChangeSoundID)
      print("🔊 [토글 오디오] switch_change 사운드 재생 완료 (SystemSoundID 방식)")
    } else {
      print("❌ [토글 오디오] 모든 재생 방법 실패")
    }
  }
  
  /// Switch와 Handle 엔티티를 찾아서 설정
  func setupSwitchHandles(rootEntity: Entity) async {
    // 유연한 Room 엔티티 찾기
    guard let roomEntity = entitySearchManager.findRoomEntity(from: rootEntity) else {
      print("❌ Room 엔티티를 찾을 수 없음 - 유연한 검색 실패")
      return
    }
    
    print("✅ Room 엔티티 발견: \(roomEntity.name)")
    print("🔍 Room 엔티티 구조 분석:")
    analyzeEntityStructure(roomEntity, depth: 0)
    
    // Switch 1~5 모든 스위치를 동일한 방식으로 처리
    for switchIndex in 1...5 {
      if let switchEntity = entitySearchManager.findSwitchEntity(in: roomEntity, switchNumber: switchIndex) {
        print("✅ Switch\(switchIndex) 발견!")
        
        // SwitchComponent 추가
        switchEntity.components.set(SwitchComponent(switchIndex: switchIndex))
        
        // Switch1의 경우 Handle1이 없을 수 있으므로 별도 처리
        if switchIndex == 1 {
          // Switch1: Handle1이 나중에 HandleManager에서 생성되므로 Joint만 저장
          if let joint = findJointEntity(in: switchEntity) {
            switchJoints[switchIndex] = joint
            print("✅ Switch1 Joint 저장 완료: \(joint.name)")
            print("  - Joint 위치: \(joint.position)")
            print("  - Joint 타입: \(type(of: joint))")
          } else {
            print("⚠️ Switch1에서 Joint를 찾을 수 없음 - 구조 분석:")
            analyzeEntityStructure(switchEntity, depth: 0)
          }
        } else {
          // Switch2~5: 기존 로직 (Handle 찾기 및 설정)
          if let handle = entitySearchManager.findHandleEntity(in: switchEntity, handleNumber: 1) {
            // Joint 찾기
            if let joint = findJointEntity(in: switchEntity) {
              switchJoints[switchIndex] = joint
              setupHandleForDragging(handle, switchIndex: switchIndex, joint: joint)
              print("✅ Switch\(switchIndex) Handle1 및 Joint 설정 완료")
            } else {
              print("⚠️ Switch\(switchIndex)에서 Joint를 찾을 수 없음 - Handle만 설정")
              setupHandleForDragging(handle, switchIndex: switchIndex, joint: nil)
            }
          } else {
            print("⚠️ Switch\(switchIndex)에서 Handle1을 찾을 수 없음 - 구조 분석:")
            analyzeEntityStructure(switchEntity, depth: 0)
          }
        }
      } else {
        print("⚠️ Switch\(switchIndex)를 찾을 수 없음")
      }
    }
  }
  
  /// Switch 상태 토글 및 애니메이션 실행
  func toggleSwitchState(switchEntity: Entity, handleEntity: Entity, isUpward: Bool) {
    guard let switchComponent = switchEntity.components[SwitchComponent.self] else {
      print("❌ [토글 실패] SwitchComponent를 찾을 수 없음 - Entity: \(switchEntity.name)")
      return
    }
    
    let switchIndex = switchComponent.switchIndex
    print("🔄 [토글 시작] Switch\(switchIndex) 제스처: \(isUpward ? "위로" : "아래로")")
    print("  - Switch Entity: \(switchEntity.name)")
    print("  - Handle Entity: \(handleEntity.name)")
    
    // 스위치 상태 토글 (제스처 방향과 무관하게 현재 상태를 토글)
    updateSwitchState(switchIndex: switchIndex, isUpward: isUpward)
    
    // 토글된 상태에 따라 애니메이션 방향 결정
    let currentState = switchStates[switchIndex] ?? 0
    let shouldAnimateUp = currentState == 0  // 상태 0 = 위로, 상태 1 = 아래로
    
    print("🎬 [애니메이션 방향] 토글된 상태: \(currentState) → 애니메이션: \(shouldAnimateUp ? "위로" : "아래로")")
    
    // Handle 애니메이션 실행 (토글된 상태에 따라)
    animateHandle(handleEntity, isUp: shouldAnimateUp, switchIndex: switchIndex)
  }
  
  /// 스위치 상태 업데이트 및 전체 상태 출력
  private func updateSwitchState(switchIndex: Int, isUpward: Bool) {
    // 제스처 방향에 따라 직접 상태 설정 (토글 방식 제거)
    let currentState = switchStates[switchIndex] ?? 0
    let newState = isUpward ? 0 : 1  // 위 제스처 = 0(위), 아래 제스처 = 1(아래)
    
    print("🔍 [제스처 → 상태] Switch\(switchIndex) - 제스처: \(isUpward ? "위로" : "아래로") → 상태: \(newState)")
    print("   └─ 이전: \(currentState) → 새로운: \(newState)")
    print("   └─ 핸들 위치: \(newState == 1 ? "아래로(-45도)" : "위로(+15도)")")
    
    // 상태가 실제로 변경된 경우에만 사운드 재생 및 로그 출력
    if newState != currentState {
      // 상태 업데이트
      switchStates[switchIndex] = newState
      
      // Switch 토글 사운드 재생
      print("🔊 [사운드 호출] 상태 변경됨 - playSwitchChangeSound 호출 시작...")
      playSwitchChangeSound()
      
      // 전체 스위치 상태 출력
      printAllSwitchStates()
    } else {
      print("🔄 [상태 유지] Switch\(switchIndex): 이미 \(newState == 1 ? "아래" : "위") 상태 - 변경 없음")
      print("❌ [사운드 스킵] 상태 변화가 없어서 사운드 재생하지 않음")
    }
  }
  
  /// 모든 스위치 상태를 "00000~11111" 형태로 출력
  private func printAllSwitchStates() {
    let state1 = switchStates[1] ?? 0
    let state2 = switchStates[2] ?? 0
    let state3 = switchStates[3] ?? 0
    let state4 = switchStates[4] ?? 0
    let state5 = switchStates[5] ?? 0
    
    let stateString = "\(state1)\(state2)\(state3)\(state4)\(state5)"
    print("📊 [핸들 상태] \(stateString)")
    
    // 각 스위치별 상세 정보 출력 (실제 시각적 상태에 맞게: 0=위, 1=아래)
    print("   └─ Switch1:\(state1)(\(state1 == 1 ? "아래" : "위")) Switch2:\(state2)(\(state2 == 1 ? "아래" : "위")) Switch3:\(state3)(\(state3 == 1 ? "아래" : "위")) Switch4:\(state4)(\(state4 == 1 ? "아래" : "위")) Switch5:\(state5)(\(state5 == 1 ? "아래" : "위"))")
    
    // 특별 상태(01100) 체크 및 사운드 재생
    if stateString == "01100" {
      print("🎯 [특별 상태 감지] 01100 패턴 달성!")
        NotificationCenter.default.post(name: NSNotification.Name("openVent"), object: nil)
//      playSpecialStateSound()
    }
  }
  
  /// Handle을 원래 위치로 되돌리기
  func resetHandlePosition(handleEntity: Entity) {
    print("Handle 위치 리셋")
    // switchIndex를 찾기 위해 부모 엔티티 검색
    if let switchParent = findSwitchParentForHandle(handleEntity),
       let switchComponent = switchParent.components[SwitchComponent.self] {
      animateHandle(handleEntity, isUp: false, switchIndex: switchComponent.switchIndex)
    } else {
      // switchIndex를 찾을 수 없는 경우 기본 애니메이션
      animateHandle(handleEntity, isUp: false, switchIndex: 0)
    }
  }
  
  // MARK: - Private Methods
  
  /// 엔티티 구조 분석 (디버깅용)
  private func analyzeEntityStructure(_ entity: Entity, depth: Int) {
    let indent = String(repeating: "  ", count: depth)
    print("\(indent)📋 \(entity.name) (타입: \(type(of: entity)))")
    
    for child in entity.children {
      analyzeEntityStructure(child, depth: depth + 1)
    }
  }
  
  // MARK: - Entity Finding Methods (moved to EntitySearchManager)
  
  /// Joint 엔티티 찾기 (다양한 이름 패턴 시도)
  private func findJointEntity(in switchEntity: Entity) -> Entity? {
    let possibleNames = [
      "Joint", "joint", "JOINT",
      "Joint1", "joint1", "JOINT1",
      "Pivot", "pivot", "PIVOT",
      "Hinge", "hinge", "HINGE"
    ]
    
    for name in possibleNames {
      if let entity = switchEntity.findEntity(named: name) {
        print("Joint 발견: '\(name)'")
        return entity
      }
    }
    
    // 이름에 joint, pivot, hinge가 포함된 엔티티들을 재귀적으로 찾기
    return entitySearchManager.findEntityContainingKeyword(keyword: "joint", in: switchEntity) ??
           entitySearchManager.findEntityContainingKeyword(keyword: "pivot", in: switchEntity) ??
           entitySearchManager.findEntityContainingKeyword(keyword: "hinge", in: switchEntity)
  }
  
  // MARK: - Helper Methods (moved to specialized managers)
  
  /// Handle을 드래그 가능하도록 설정
  private func setupHandleForDragging(_ handle: Entity, switchIndex: Int, joint: Entity?) {
    handle.components.set(DraggableComponent())
    handle.components.set(InputTargetComponent())
    
    // Handle과 Joint가 같은 위치일 때 Handle을 적절한 위치로 이동
    if let joint = joint {
      let handleJointDistance = entitySearchManager.distance(handle.position, joint.position)
      if handleJointDistance < 0.001 {
        print("⚠️ Handle\(switchIndex)과 Joint가 같은 위치! Handle을 적절한 위치로 이동")
        // Handle을 Joint 앞쪽(X축 양의 방향)으로 4cm 이동
        let offsetPosition = SIMD3<Float>(
          joint.position.x + 0.04,  // 4cm 앞으로
          joint.position.y,
          joint.position.z
        )
        handle.position = offsetPosition
        print("  - Handle 위치 조정: \(joint.position) → \(offsetPosition)")
      }
    }
    
    // 핸들의 초기 orientation과 position 저장 (조정 후)
    handleInitialOrientations[switchIndex] = handle.orientation
    handleInitialPositions[switchIndex] = handle.position
    
    print("Handle\(switchIndex) 초기 상태 저장:")
    print("  - Orientation: \(handle.orientation)")
    print("  - Position: \(handle.position)")
    
    if let joint = joint {
      print("  - Joint Position: \(joint.position)")
      print("  - Handle-Joint 거리: \(distance(handle.position, joint.position))")
    }
    
    // 물리 컴포넌트를 static 모드로 설정하여 위치 고정
    let physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: .default,
      mode: .static  // kinematic에서 static으로 변경하여 완전히 고정
    )
    handle.components.set(physicsBody)
    handle.generateCollisionShapes(recursive: true)
    
    print("Handle\(switchIndex) 드래그 설정 완료 (Joint 기준 회전)")
  }
  
  // MARK: - Distance calculation moved to EntitySearchManager
  
  /// Handle의 부모 Switch 엔티티 찾기
  private func findSwitchParentForHandle(_ handle: Entity) -> Entity? {
    var currentEntity: Entity? = handle.parent
    
    while let current = currentEntity {
      if current.components[SwitchComponent.self] != nil {
        return current
      }
      currentEntity = current.parent
    }
    return nil
  }
  
  /// Handle 애니메이션 (위/아래) - Joint 중심 아크 움직임
  private func animateHandle(_ handle: Entity, isUp: Bool, switchIndex: Int) {
    print("🎬 [애니메이션] Handle\(switchIndex) 애니메이션 시작")
    
    // 위로 드래그: +15도, 아래로 드래그: -45도
    let targetAngle: Float = isUp ? 0.262 : -0.785 // 라디안 단위 (+15도 / -45도)
    
    // Switch1은 간단한 Transform 애니메이션 사용
    if switchIndex == 1 {
      print("🔧 [Switch1 특별 애니메이션] 간단한 Transform 애니메이션 사용")
      animateSwitch1Handle(handle, isUp: isUp, angle: targetAngle)
      return
    }
    
    // Switch2~5는 기존 Joint 중심 회전 사용
    if let joint = switchJoints[switchIndex] {
      print("🔄 [Joint 애니메이션] Handle\(switchIndex) Joint 중심 애니메이션: \(isUp ? "위로 +15도" : "아래로 -45도")")
      animateHandleAroundJoint(handle: handle, joint: joint, angle: targetAngle, switchIndex: switchIndex)
    } else {
      print("⚠️ [기본 애니메이션] Handle\(switchIndex) 기본 애니메이션 (Joint 없음): \(isUp ? "위로 +15도" : "아래로 -45도")")
      
      // Joint가 없는 경우 기본 회전
      guard let initialOrientation = handleInitialOrientations[switchIndex] else {
        print("❌ [애니메이션 실패] Handle\(switchIndex) 초기 방향 정보 없음 - 기본 회전 적용")
        let targetOrientation = simd_quatf(angle: targetAngle, axis: [1, 0, 0])
        animateToTransform(handle, position: handle.position, orientation: targetOrientation)
        return
      }
      
      let relativeQuaternion = simd_quatf(angle: targetAngle, axis: [1, 0, 0])
      let targetOrientation = initialOrientation * relativeQuaternion
      animateToTransform(handle, position: handle.position, orientation: targetOrientation)
    }
  }
  
  /// Switch1 전용 간단한 Transform 애니메이션
  private func animateSwitch1Handle(_ handle: Entity, isUp: Bool, angle: Float) {
    guard let initialPosition = handleInitialPositions[1],
          let initialOrientation = handleInitialOrientations[1] else {
      print("❌ [Switch1 애니메이션] 초기 상태 정보 없음")
      return
    }
    
    print("🎯 [Switch1 애니메이션] 세로 Transform 애니메이션 시작")
    print("  - 방향: \(isUp ? "위로 +15도" : "아래로 -45도")")
    print("  - 초기 위치: \(initialPosition)")
    print("  - 초기 방향: \(initialOrientation)")
    
    // 세로 방향 위치 이동 계산 (Z축 방향으로 이동 - 앞뒤)
    let moveDistance: Float = isUp ? 0.015 : -0.025 // 위로 1.5cm, 아래로 2.5cm (세로)
    let targetPosition = SIMD3<Float>(
      initialPosition.x,
      initialPosition.y,
      initialPosition.z + moveDistance  // Z축 이동으로 세로 효과
    )
    
    // Switch2~5와 동일한 X축 회전 사용
    let targetOrientation = initialOrientation * simd_quatf(angle: angle, axis: [1, 0, 0]) // X축 회전
    
    print("  - 목표 위치: \(targetPosition)")
    print("  - 목표 방향: \(targetOrientation)")
    print("  - 세로 이동 거리: \(moveDistance)m (Z축)")
    print("  - 회전축: X축 (Switch2~5와 동일)")
    print("  - 회전 각도: \(angle * 180 / .pi)도")
    
    // Transform 애니메이션 실행
    let animation = FromToByAnimation<Transform>(
      from: Transform(scale: handle.scale, rotation: handle.orientation, translation: handle.position),
      to: Transform(scale: handle.scale, rotation: targetOrientation, translation: targetPosition),
      duration: 0.3,
      timing: .easeOut,
      bindTarget: .transform
    )
    
    do {
      let animationResource = try AnimationResource.generate(with: animation)
      handle.playAnimation(animationResource)
      print("✅ [Switch1 애니메이션] 세로 Transform 애니메이션 실행 완료")
    } catch {
      print("❌ [Switch1 애니메이션] 애니메이션 생성 실패: \(error)")
    }
  }
  
  /// Joint 중심으로 핸들을 아크 모양으로 회전시키는 함수 (거리 일정 유지)
  private func animateHandleAroundJoint(handle: Entity, joint: Entity, angle: Float, switchIndex: Int) {
    guard let initialPosition = handleInitialPositions[switchIndex],
          let initialOrientation = handleInitialOrientations[switchIndex] else {
      print("Handle\(switchIndex)의 초기 상태를 찾을 수 없음")
      return
    }
    
    // Handle과 Joint 사이의 벡터 계산
    let handleToJointVector = initialPosition - joint.position
    let jointToHandleDistance = sqrt(handleToJointVector.x * handleToJointVector.x + 
                                   handleToJointVector.y * handleToJointVector.y + 
                                   handleToJointVector.z * handleToJointVector.z)
    
    // 거리가 0이거나 너무 작으면 기본 애니메이션
    if jointToHandleDistance < 0.001 {
      print("⚠️ Handle과 Joint가 같은 위치! 기본 애니메이션 적용")
      let relativeQuaternion = simd_quatf(angle: angle, axis: [1, 0, 0])
      let targetOrientation = initialOrientation * relativeQuaternion
      animateToTransform(handle, position: initialPosition, orientation: targetOrientation)
      return
    }
    
    // Joint를 중심으로 하는 완전한 원형 궤도 계산
    // Joint를 원점으로 하는 좌표계에서 핸들의 상대 위치
    let relativePosition = initialPosition - joint.position
    
    // Switch1은 Y축 회전, Switch2~5는 X축 회전 사용
    let rotationAxis: SIMD3<Float> = (switchIndex == 1) ? [0, 1, 0] : [1, 0, 0]
    let axisName = (switchIndex == 1) ? "Y축" : "X축"
    
    print("🔄 [회전축] Switch\(switchIndex): \(axisName) 회전 사용")
    
    // 회전 행렬 적용 (Joint와의 거리를 정확히 유지)
    let rotationMatrix = simd_float4x4(simd_quatf(angle: angle, axis: rotationAxis))
    let rotatedVector4D = rotationMatrix * SIMD4<Float>(relativePosition.x, relativePosition.y, relativePosition.z, 0)
    let rotatedVector = SIMD3<Float>(rotatedVector4D.x, rotatedVector4D.y, rotatedVector4D.z)
    
    // 새로운 절대 위치 계산 (Joint 위치 + 회전된 상대 위치)
    let newPosition = joint.position + rotatedVector
    
    // 거리 검증 (디버깅용)
    let newDistance = entitySearchManager.distance(newPosition, joint.position)
    
    // 새로운 orientation 계산 (회전축에 맞게)
    let relativeQuaternion = simd_quatf(angle: angle, axis: rotationAxis)
    let newOrientation = initialOrientation * relativeQuaternion
    
    print("🔄 Joint 중심 원형 회전 (Handle\(switchIndex)):")
    print("  - 회전축: \(axisName)")
    print("  - Joint 위치: \(joint.position)")
    print("  - 초기 핸들 위치: \(initialPosition)")
    print("  - 새 핸들 위치: \(newPosition)")
    print("  - 초기 Joint-Handle 거리: \(jointToHandleDistance)m")
    print("  - 회전 후 Joint-Handle 거리: \(newDistance)m")
    print("  - 거리 변화: \(abs(newDistance - jointToHandleDistance))m")
    print("  - 회전 각도: \(angle * 180 / .pi)도")
    
    // 거리 차이가 1mm 이상이면 경고
    if abs(newDistance - jointToHandleDistance) > 0.001 {
      print("⚠️ 거리 일관성 문제 감지!")
    } else {
      print("✅ 거리 일관성 유지됨")
    }
    
    // 애니메이션 실행
    animateToTransform(handle, position: newPosition, orientation: newOrientation)
  }
  
  /// 지정된 위치와 방향으로 애니메이션 (Joint 중심 아크 움직임용)
  private func animateToTransform(_ handle: Entity, position: SIMD3<Float>, orientation: simd_quatf) {
    // 위치와 회전을 모두 포함한 애니메이션 생성
    let animation = FromToByAnimation<Transform>(
      from: Transform(scale: handle.scale, rotation: handle.orientation, translation: handle.position),
      to: Transform(scale: handle.scale, rotation: orientation, translation: position),
      duration: 0.4,
      timing: .easeOut,
      bindTarget: .transform
    )
    
    do {
      let animationResource = try AnimationResource.generate(with: animation)
      handle.playAnimation(animationResource)
    } catch {
      print("Handle 애니메이션 생성 실패: \(error)")
    }
  }
  
  // MARK: - Internal Access Methods
  
  func getSwitchJoint(for switchIndex: Int) -> Entity? {
    return switchJoints[switchIndex]
  }
  
  func getHandleInitialOrientation(for switchIndex: Int) -> simd_quatf? {
    return handleInitialOrientations[switchIndex]
  }
  
  func getHandleInitialPosition(for switchIndex: Int) -> SIMD3<Float>? {
    return handleInitialPositions[switchIndex]
  }
  
  func setHandleInitialOrientation(_ orientation: simd_quatf, for switchIndex: Int) {
    handleInitialOrientations[switchIndex] = orientation
  }
  
  func setHandleInitialPosition(_ position: SIMD3<Float>, for switchIndex: Int) {
    handleInitialPositions[switchIndex] = position
  }
  
  /// Handle을 SwitchManager에 등록하여 토글 기능 활성화
  func registerHandle(_ handle: Entity, forSwitchIndex switchIndex: Int, withJoint joint: Entity?) {
    print("🎮 [Switch 등록] Handle 등록 시작 - Switch\(switchIndex)")
    print("  - Handle 이름: \(handle.name)")
    print("  - Handle 위치: \(handle.position)")
    print("  - Handle 방향: \(handle.orientation)")
    
    // Switch2~5와 동일한 setupHandleForDragging 호출
    print("🔧 [동일 설정] Switch\(switchIndex)에 setupHandleForDragging 적용")
    setupHandleForDragging(handle, switchIndex: switchIndex, joint: joint)
    
    print("✅ [Switch 등록] Switch\(switchIndex) Handle 등록 완료 - Switch2~5와 동일한 방식으로 처리됨")
  }
  
  /// SystemSoundID 방식으로 사운드 재생
  private func playSystemSound() {
    if switchChangeSoundID != 0 {
      AudioServicesPlaySystemSound(switchChangeSoundID)
      print("🔊 [SystemSound] switch_change 사운드 재생 완료")
    } else {
      print("❌ [SystemSound] SystemSoundID가 설정되지 않음")
    }
  }
  
  /// 특별 상태(01100) 달성 시 11.mp3 사운드 재생
  private func playSpecialStateSound() {
    guard let player = specialStateAudioPlayer else {
      print("❌ [특별 상태 오디오] 미리 로딩된 11.mp3 플레이어가 없음")
      return
    }
    
    // 이미 재생 중이면 처음부터 다시 재생
    if player.isPlaying {
      player.stop()
      player.currentTime = 0
    }
    
    let success = player.play()
    if success {
      print("🎉 [특별 상태 달성] 01100 상태 - 11.mp3 사운드 재생!")
    } else {
      print("❌ [특별 상태 오디오] 11.mp3 재생 실패")
    }
  }
} 
