//
//  ARTutorial.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/24/25.
//

import SwiftUI
import ARKit
import RealityKit

struct ARTutorial: View {
  @Binding var isPresented: Bool
  @State private var showSoundTutorial: Bool = false
  var body: some View {
    ZStack {
      Color.clear.ignoresSafeArea()
      
      VStack {
        Text("⚠️ 안전을 위해 장애물이 없는 반경 약 2m 이상의 빈 공간에서 플레이 하세요!")
          .font(.system(size: 30))
          .fontWeight(.bold)
        
        Button("다음") {
          showSoundTutorial = true
        }
        .padding(.top, 50)
      }
      .background(.clear)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.clear)
    }
    .fullScreenCover(isPresented: $showSoundTutorial) {
      SoundTutorial(isPresented: $showSoundTutorial)
    }
  }
}

#Preview {
  ARTutorial(isPresented: .constant(true))
}
