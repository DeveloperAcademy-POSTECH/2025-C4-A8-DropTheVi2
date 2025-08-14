//
//  SoundManager.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/23/25.
//

import AVFoundation
import Foundation

@Observable
final class SoundManager {
  static let shared = SoundManager()
  private var audioPlayers: [String: AVAudioPlayer] = [:]
  
  private init() {
    setupAudioSession()
    preloadSounds()
  }
  
  enum Sound: String, CaseIterable {
    case buttonTap = "keypad_tap"
    case success = "keypad_success"
    case fail = "keypad_wrong"
    case maintheme = "maintheme"
    case gamestart = "gamestart"
    case monitorTap = "monitor_tap"
    case monitorsuccess = "monitor_success"
    case doorTap = "door_locked"
    case gasAlert = "gasAlert"
    case ventOpen = "ventOpen"
    case openDesk = "DeskSound"
  }
  // MARK: - 오디오 세션 설정
  private func setupAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Error setting up audio session: \(error)")
    }
  }
  // MARK: - 사운드 초기화 시점 미리 로드
  private func preloadSounds() {
    Sound.allCases.forEach { loadSound($0.rawValue) }
  }
  // MARK: - url 번들 찾고 AudioPlayer 로드
  private func loadSound(_ soundName: String) {
    guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
      return
    }
    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.prepareToPlay()
      audioPlayers[soundName] = player
    } catch {
      print("사운드 로드 실패")
    }
  }
  
  // MARK: - 음악 재생 로직
  func playSound(_ effect: Sound, volume: Float = 1.0) {
    guard let player = audioPlayers[effect.rawValue] else {
      print("사운드 플레이어 없음")
      return
    }
    player.volume = volume
    player.currentTime = 0
    player.play()
  }
  
  // MARK: - 언어별 알림 사운드 재생
  func playLocalizedWarningSound(volume: Float = 2.0) {
    let soundFileName = NSLocalizedString("warningSound", comment: "Warning sound file name")
    playLocalizedSound(fileName: soundFileName, volume: volume)
  }
  
  func playLocalizedProblemSolvedSound(volume: Float = 2.0) {
    let soundFileName = NSLocalizedString("problemSolvedSound", comment: "Problem solved sound file name")
    playLocalizedSound(fileName: soundFileName, volume: volume)
  }
  
  // MARK: - 언어별 알림 사운드 정지
  func pauseLocalizedWarningSound() {
    let soundFileName = NSLocalizedString("warningSound", comment: "Warning sound file name")
    pauseLocalizedSound(fileName: soundFileName)
  }
  
  // MARK: - 헬퍼 메서드
  private func playLocalizedSound(fileName: String, volume: Float) {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
      print("로컬라이즈된 사운드 파일을 찾을 수 없음: \(fileName)")
      return
    }
    
    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.volume = volume
      player.prepareToPlay()
      player.play()
      
      // 임시로 플레이어 저장 (정지 기능을 위해)
      audioPlayers[fileName] = player
    } catch {
      print("로컬라이즈된 사운드 재생 실패: \(fileName), 오류: \(error)")
    }
  }
  
  private func pauseLocalizedSound(fileName: String) {
    if let player = audioPlayers[fileName] {
      player.stop()
      player.currentTime = 0
    } else {
      print("정지할 로컬라이즈된 사운드 플레이어를 찾을 수 없음: \(fileName)")
    }
  }
  
  func pausedSound(_ effect: Sound) {
    guard let player = audioPlayers[effect.rawValue] else {
      print("사운드 플레이어 없음")
      return
    }
    player.stop()
    player.currentTime = 0
  }
}
