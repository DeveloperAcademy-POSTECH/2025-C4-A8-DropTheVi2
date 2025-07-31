//
//  SwitchDropSoundManager.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import AVFoundation

@MainActor
final class SwitchDropSoundManager {
  static let shared = SwitchDropSoundManager()
  
  // 드롭 사운드 플레이어 (switchdrop.mp3용)
  private var dropAudioPlayer: AVAudioPlayer?
  
  private init() {
    // switchdrop.mp3 사운드 미리 로딩
    preloadSwitchDropSound()
  }
  
  /// switchdrop.mp3 사운드를 미리 로딩하여 즉시 재생 준비
  private func preloadSwitchDropSound() {
    guard let soundPath = Bundle.main.path(forResource: "switchdrop", ofType: "mp3") else {
      print("❌ [드롭 오디오 미리로딩] switchdrop.mp3 파일을 찾을 수 없음")
      return
    }
    
    do {
      let soundURL = URL(fileURLWithPath: soundPath)
      dropAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
      dropAudioPlayer?.volume = 0.8
      dropAudioPlayer?.prepareToPlay()  // 미리 로딩
      
      // 더미 재생으로 완전한 초기화 (무음으로 실제 재생)
      let originalVolume = dropAudioPlayer?.volume ?? 0.8
      dropAudioPlayer?.volume = 0.0  // 무음으로 설정
      dropAudioPlayer?.play()  // 실제로 재생
      
      // 0.1초 후 정지하고 볼륨 복원
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.dropAudioPlayer?.stop()
        self?.dropAudioPlayer?.currentTime = 0
        self?.dropAudioPlayer?.volume = originalVolume  // 원래 볼륨 복원
        print("✅ [드롭 오디오 미리로딩] switchdrop.mp3 사운드 더미 재생 완료 - 즉시 재생 준비됨")
      }
      
    } catch {
      print("❌ [드롭 오디오 미리로딩] switchdrop.mp3 사운드 로딩 실패: \(error)")
    }
  }
  
  /// HandleDetached가 바닥에 떨어질 때 switchdrop.mp3 사운드 재생
  func playSwitchDropSound() {
    guard let player = dropAudioPlayer else {
      print("❌ [드롭 오디오] 미리 로딩된 드롭 오디오 플레이어가 없음")
      return
    }
    
    // 이미 재생 중이면 처음부터 다시 재생
    if player.isPlaying {
      player.stop()
      player.currentTime = 0
    }
    
    let success = player.play()
    if success {
      print("🔊 [드롭 오디오] switchdrop.mp3 사운드 즉시 재생 (미리 로딩됨)")
    } else {
      print("❌ [드롭 오디오] switchdrop.mp3 재생 실패")
    }
  }
} 