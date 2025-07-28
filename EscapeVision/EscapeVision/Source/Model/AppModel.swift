//
//  AppModel.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/12/25.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
  let immersiveSpaceID = "ImmersiveSpace"
  
  var isWhiteoutActive = false
  
  enum ImmersiveSpaceState {
    case closed
    case inTransition
    case open
  }
  
  enum AppState {
    case splash
    case guideline
    case menu
    case playing
  }
  
  var immersiveSpaceState = ImmersiveSpaceState.closed
  var appState = AppState.splash // 앱 시작 시 가이드라인부터
  
  var needsImmersiveSpace: Bool {
    return appState == .guideline || appState == .playing
  }
  
  // MARK: - Game State Management
  func showGuideline() {
    print("가이드라인 화면 동작")
    appState = .guideline
  }
  
  func showMainMenu() {
    print("메뉴화면으로 이동")
    appState = .menu
  }
  
  func startGame() {
    print("🎮 게임 시작")
    appState = .playing
  }
  
  // MARK: - Computed Properties
  var isShowingGuideline: Bool {
    return appState == .guideline
  }
  
  var isGameActive: Bool {
    return appState == .playing
  }
  
  var isShowingSplash: Bool {
    return appState == .splash
  }
}
