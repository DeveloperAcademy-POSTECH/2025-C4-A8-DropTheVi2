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
    @State private var soundManager = SoundManager.shared
    
    var body: some View {
        VStack {
            if appModel.appState == .splash {
                SplashView()
            } else if appModel.appState == .guideline {
                GuidelineWindowView()
            } else if appModel.appState == .menu || appModel.appState == .playing || appModel.appState == .loading {
                MainThemeView()
            }
        }
        .onChange(of: appModel.needsImmersiveSpace) {oldValue, newValue in
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
        // ✨ Maintheme Play
        .onChange(of: appModel.appState) { _, newState in
            if [.splash, .guideline, .menu].contains(newState) {
                soundManager.playSound(.maintheme, volume: 1.0)
            } else if [.loading ].contains(newState) {
                soundManager.playSound(.gamestart, volume: 2.0)
            }
        }
        // ✨ 앱 시작 시 초기 음악
        .onAppear {
            soundManager.playSound(.maintheme, volume: 1.0)
        }
    }
}

#Preview() {
    let appModel = AppModel()
    appModel.appState = .splash
    return ContentView()
        .environment(appModel)
}
