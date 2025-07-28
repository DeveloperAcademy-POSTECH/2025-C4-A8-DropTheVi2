//
//  ContentView.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/12/25.
//

import Foundation
import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
  @Environment(AppModel.self) private var appModel
  @Environment(\.openImmersiveSpace) private var openImmersiveSpace
  @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
  
  var body: some View {
    ZStack {
      if appModel.appState == .splash {
        SplashView()
      } else if appModel.appState == .guideline {
        GuidelineWindowView()
      } else if appModel.appState == .menu {
        MainThemeView()
      } else if appModel.appState == .playing {
        VStack {
          Text("게임 진행 중..")
        }
      }
    }
    .onChange(of: appModel.needsImmersiveSpace) { oldValue, newValue in
      Task { @MainActor in
        if newValue && appModel.immersiveSpaceState == .closed {
          appModel.immersiveSpaceState = .inTransition
          
          await openImmersiveSpace(id: appModel.immersiveSpaceID)
        } else if !newValue && appModel.immersiveSpaceState == .open {
          appModel.immersiveSpaceState = .inTransition
          
          await dismissImmersiveSpace()
        }
      }
    }
  }
}

#Preview() {
  let appModel = AppModel()
  appModel.appState = .splash
  return ContentView()
    .environment(appModel)
}
