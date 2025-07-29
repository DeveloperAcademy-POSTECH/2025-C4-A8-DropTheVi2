//
//  SplashView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/26/25.
//

import SwiftUI

struct SplashView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showAlert: Bool = true
    @State private var soundManager = SoundManager.shared
    
    var body: some View {
        ZStack {
            VStack(spacing: 35) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 47.5, weight: .bold))
                        .foregroundStyle(.white)
                    Text("강한 소리에 주의하세요")
                        .font(.system(size: 47.5, weight: .bold))
                }
                VStack(spacing: 6) {
                    Text("이 앱은 강한 사운드를 포함합니다")
                        .font(.system(size: 37.5, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text("볼륨을 확인해주세요")
                        .font(.system(size: 37.5, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .padding(.horizontal, 70)
                    .padding(.top, 10)
                
                Button(action: {
                    appModel.showGuideline()
                    soundManager.playSound(.buttonTap, volume: 1.5)
                }, label: {
                    Text("시작하기")
                        .font(.system(size: 42.5, weight: .semibold))
                })
                .buttonStyle(.plain)
                .padding(.top, 30)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: 800, maxHeight: 490)
        .glassBackgroundEffect()
        .cornerRadius(80)
    }
}

#Preview {
    SplashView()
        .environment(AppModel())
}
