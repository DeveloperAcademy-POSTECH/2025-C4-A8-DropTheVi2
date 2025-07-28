//
//  SplashView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/26/25.
//

import SwiftUI

struct SplashView: View {
  @Environment(AppModel.self) private var appModel
  
  var body: some View {
    ZStack {
      Color.black
      VStack(spacing: 16) {
        HStack {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 44, weight: .bold))
            .foregroundStyle(.yellow)
          Text("주의")
            .font(.system(size: 48, weight: .bold))
        }
        .padding(.bottom, 12)
        .padding(.top, 90)
        
        Text("이 앱은 강한 사운드를 포함하고 있습니다.")
          .font(.system(size: 30, weight: .regular))
          .foregroundStyle(.white)
        Text("시작 전 음량을 적절한 크기로 조정해주세요.")
          .font(.system(size: 30, weight: .light))
          .foregroundStyle(.white)
        
        Button(action: {
          appModel.showGuideline()
        }, label: {
          Text("확인헀습니다.")
            .font(.system(size: 24, weight: .bold))
            .padding(.vertical, 15)
            .padding(.horizontal, 10)
        })
        .padding(.top, 100)
      }
    }
  }
}

#Preview {
    SplashView()
    .environment(AppModel())
}
