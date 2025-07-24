//
//  ContentView.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/12/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
  @State private var showARTutorial: Bool = false
  
  var body: some View {
    VStack {
      
      Text("Hello, world!")
        
      HStack {
        Button("튜토리얼") {
          showARTutorial = true
        }
        .buttonStyle(.borderedProminent)
        .opacity(0.5)
        
        ToggleImmersiveSpaceButton()
          .buttonStyle(.borderedProminent)
          .opacity(0.5)
      }
      .padding(.top, 50)
    }
    .padding()
    .fullScreenCover(isPresented: $showARTutorial, content: {
      ARTutorial(isPresented: $showARTutorial)
    })
    .animation(.easeInOut(duration: 0.3), value: showARTutorial)
  }
}

#Preview(windowStyle: .automatic) {
  ContentView()
    .environment(AppModel())
}
