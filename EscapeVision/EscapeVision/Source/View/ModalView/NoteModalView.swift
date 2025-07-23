//
//  NoteModalView.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/23/25.
//

import SwiftUI

struct NoteModalView: View {
  @State private var glowOpacity: Double = 0.3
  @State private var floatOffset: CGFloat = 0
  
  @State private var isVisible = false
  
  var body: some View {
    Image("BoxNote")
      .scaleEffect(isVisible ? 1 : 0.2, anchor: .bottom)
    // 2) 박스 위치보다 아래(200 포인트)에서 시작 → 제자리로 슬라이드 업
      .offset(y: isVisible ? 0 : 200)
    // 3) 불투명도도 0 → 1
      .opacity(isVisible ? 1 : 0)
    // 4) onAppear에서 한 번에 스프링 애니메이션 트리거
      .onAppear {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
          isVisible = true
        }
      }
  }
}

#Preview {
    NoteModalView()
}
