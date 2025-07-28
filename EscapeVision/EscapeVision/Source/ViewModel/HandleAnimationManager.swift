//
//  HandleAnimationManager.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AudioToolbox

@MainActor
final class HandleAnimationManager {
  static let shared = HandleAnimationManager()
  private init() {}
  
  /// 상자 뚜껑 열기 애니메이션
  func playOpenLidAnimation() {
    // RoomViewModel의 rootEntity를 통해 Box를 찾아서 애니메이션 실행
    let roomViewModel = RoomViewModel.shared
    let rootEntity = roomViewModel.rootEntity
    
    guard let firstRoot = rootEntity.children.first,
          let secondRoot = firstRoot.children.first,
          let box = secondRoot.findEntity(named: "BoxTest")?.findEntity(named: "Box") else {
      print("애니메이션 Box 찾을 수 없음")
      return
    }
    
    print("사용 가능한 애니메이션들:")
    for animation in box.availableAnimations {
      print("\(animation.name ?? "이름없음")")
    }
    
    if let lid = box.findEntity(named: "Lid") {
      print("Lid 애니메이션 개수: \(lid.availableAnimations.count)")
      if let openAnimation = lid.availableAnimations.first(where: { $0.name == "OpenLid" }) {
        lid.playAnimation(openAnimation)
        print("🎬 뚜껑 열기 애니메이션 재생")
      } else {
        print("❌ OpenLid 애니메이션을 찾을 수 없음")
      }
    } else {
      print("❌ 뚜껑을 찾을 수 없음")
    }
  }
  
  /// 핸들 끼우기 애니메이션
  func playAttachAnimation(handle: Entity) {
    // 작은 진동 효과로 끼워지는 느낌 연출
    let originalPosition = handle.position
    let shakeOffset: Float = 0.005 // 5mm 진동
    
    let shakeAnimation = FromToByAnimation<Transform>(
      from: Transform(scale: handle.scale, rotation: handle.orientation, translation: originalPosition),
      to: Transform(scale: handle.scale, rotation: handle.orientation, translation: SIMD3<Float>(
        originalPosition.x + shakeOffset,
        originalPosition.y,
        originalPosition.z
      )),
      duration: 0.1,
      timing: .easeInOut,
      bindTarget: .transform
    )
    
    do {
      let animationResource = try AnimationResource.generate(with: shakeAnimation)
      handle.playAnimation(animationResource)
      
      // 원래 위치로 복귀
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        let returnAnimation = FromToByAnimation<Transform>(
          from: Transform(scale: handle.scale, rotation: handle.orientation, translation: SIMD3<Float>(
            originalPosition.x + shakeOffset,
            originalPosition.y,
            originalPosition.z
          )),
          to: Transform(scale: handle.scale, rotation: handle.orientation, translation: originalPosition),
          duration: 0.1,
          timing: .easeInOut,
          bindTarget: .transform
        )
        
        do {
          let returnAnimationResource = try AnimationResource.generate(with: returnAnimation)
          handle.playAnimation(returnAnimationResource)
        } catch {
          print("복귀 애니메이션 생성 실패: \(error)")
        }
      }
    } catch {
      print("끼우기 애니메이션 생성 실패: \(error)")
    }
  }
  
  /// 효과음 재생
  func playAttachSound() {
    print("🔊 핸들 끼우기 효과음 재생")
    
    // 시스템 사운드 사용 (클릭 효과음)
    AudioServicesPlaySystemSound(1306) // 스위치 클릭 사운드
    
    // 추가적으로 진동 효과도 함께 (Vision Pro에서는 햅틱 피드백)
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
  }
} 
