//
//  GuidelineWindowView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/28/25.
//

import SwiftUI

struct GuidelineWindowView: View {
  @Environment(AppModel.self) private var appmodel
  
  var body: some View {
    ZStack {
      Color.clear.ignoresSafeArea()
      
      VStack {
        Text("⚠️ 안전을 위해 장애물이 없는 반경 약 2m 이상의 빈 공간에서 플레이 하세요.")
          .font(.system(size: 38, weight: .medium))
          .padding(.top, 120)
        
        Button(action: {
          appmodel.showMainMenu()
        }, label: {
          Text("확인했습니다.")
            .font(.system(size: 24, weight: .bold))
            .padding(.vertical, 15)
            .padding(.horizontal, 10)
        })
        .padding(.top, 143)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(.top, 40)
      
      .glassBackgroundEffect()
    }
  }
}

#Preview {
  GuidelineWindowView()
    .environment(AppModel())
}
