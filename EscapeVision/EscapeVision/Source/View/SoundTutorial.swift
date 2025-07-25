//
//  SoundTutorial.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/24/25.
//

import SwiftUI

struct SoundTutorial: View {
  @Binding var isPresented: Bool
  
  @State private var showContentView: Bool = false
  
    var body: some View {
      ZStack {
        Color.clear.ignoresSafeArea()
        
        VStack(spacing: 20) {
          Text("📢 이 앱에는 타격음, 사이렌 등 강한 소리가 포함되어 있습니다.")
            .font(.system(size: 30))
            .fontWeight(.bold)
          Text("📢 소리에 민감하신 분은 이용 시 주의해 주세요!")
            .font(.system(size: 30))
            .fontWeight(.bold)
          
          Button("완료") {
            showContentView = true
          }
          .padding(.top, 50)
        }
        .background(.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.clear)
      }
      .fullScreenCover(isPresented: $showContentView) {
        ContentView()
      }
    }
}

#Preview {
  SoundTutorial(isPresented: .constant(true))
}
