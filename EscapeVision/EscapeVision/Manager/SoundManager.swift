//
//  SoundManager.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/23/25.
//

import AVFoundation

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
}
