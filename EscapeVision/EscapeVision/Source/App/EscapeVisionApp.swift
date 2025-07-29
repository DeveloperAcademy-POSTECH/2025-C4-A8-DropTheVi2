//
//  EscapeTestApp.swift
//  EscapeTest
//
//  Created by 조재훈 on 7/12/25.
//

import SwiftUI

@main
struct EscapeTestApp: App {
  
  @State private var appModel = AppModel()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(appModel) 
    }
    .windowStyle(.plain)
    
    ImmersiveSpace(id: appModel.immersiveSpaceID) {
      // 게임 상태에 따라 다른 View 표시
      if appModel.appState == .guideline {
        GuidelineImmersiveView()
          .environment(appModel)
          .transition(.opacity.combined(with: .scale))
      } else if appModel.appState == .playing {
        RoomImmersiveView()
          .environment(appModel)
          .transition(.opacity.combined(with: .scale))
      } else if appModel.appState == .black {
          BlackImmersiveView()
              .environment(appModel)
              .transition(.opacity.combined(with: .scale))
              .animation(.easeInOut, value: appModel.appState)
      }
    }
}
