//
//  MainThemeView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/28/25.
//

import Foundation
import SwiftUI

struct MainThemeView: View {
    @Environment(AppModel.self) private var appModel
    var body: some View {
        ZStack {
            Image("IntroImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(46)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if appModel.appState == .menu {
                    Button(action: {
                        appModel.startLoad()
                    }, label: {
                        Text("Game Start")
                            .font(.system(size: 32, weight: .bold))
                            .padding(.vertical, 15)
                            .padding(.horizontal, 10)
                    })
                } else if appModel.appState == .loading {
                    ProgressView()
                        .onAppear {
                            Task {
                                try await Task.sleep(nanoseconds: 9_000_000_000)
                                await MainActor.run {
                                    appModel.startGame()
                                }
                            }
                        }
                } else if appModel.appState == .playing {
                    VStack(spacing: 20) {
                        Text("Game Paused")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Button(action: {
                            appModel.exitGame()
                        }, label: {
                            Text("Exit Game")
                                .font(.system(size: 32, weight: .bold))
                                .padding(.vertical, 15)
                                .padding(.horizontal, 10)
                        })
                    }
                }
            }
            .padding(.top, 400)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
#Preview {
    MainThemeView()
        .environment(AppModel())
}
