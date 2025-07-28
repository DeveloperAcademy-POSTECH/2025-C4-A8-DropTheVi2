//
//  GuidelineWindowView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/28/25.
//

import SwiftUI

struct GuidelineWindowView: View {
    @Environment(AppModel.self) private var appModel
    @State private var soundManager = SoundManager.shared

    var body: some View {
        ZStack {
            VStack(spacing: 35) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 47.5, weight: .bold))
                        .foregroundStyle(.white)
                    Text("공간을 확보하세요")
                        .font(.system(size: 47.5, weight: .bold))
                }
                VStack(spacing: 6) {
                    Text("화면의 빨간 선 안에")
                        .font(.system(size: 37.5, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text("가구나 장애물이 있다면 치워주세요")
                        .font(.system(size: 37.5, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .padding(.horizontal, 70)
                    .padding(.top, 10)
                
                Button(action: {
                    appModel.showMainMenu()
                    soundManager.playSound(.buttonTap, volume: 1.5)
                }, label: {
                    Text("확인했어요")
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
    GuidelineWindowView()
        .environment(AppModel())
}
