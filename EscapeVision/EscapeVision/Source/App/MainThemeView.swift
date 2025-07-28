//
//  MainThemeView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/28/25.
//

import SwiftUI

struct MainThemeView: View {
  @Environment(AppModel.self) private var appmodel
  
  var body: some View {
    VStack {
      Text("MainView")
      Button(action: {
            appmodel.startGame()
      }, label: {
        Text("게임 시작")
          .font(.system(size: 24, weight: .bold))
          .padding(.vertical, 15)
          .padding(.horizontal, 10)
      })
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .glassBackgroundEffect()
  }
}

#Preview {
  MainThemeView()
    .environment(AppModel())
}
