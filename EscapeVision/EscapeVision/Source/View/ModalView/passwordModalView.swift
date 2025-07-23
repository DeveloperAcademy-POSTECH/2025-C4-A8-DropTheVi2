//
//  passwordModalView.swift
//  EscapeTest
//
//  Created by 조재훈 on 7/20/25.
//

// visionOS 전용 PasswordModalView.swift
import SwiftUI

struct PasswordModalView: View {
  @Binding var isPresented: Bool
  @State var inputPassword: String
  @State private var showError = false
  @State private var correctPassword: String = "123"
  @Environment(\.dismiss) private var dismiss
  
  @State private var viewModel = RoomViewModel.shared
//  @State private var soundManager = SoundManager.shared
  
  @State private var animationScale: CGFloat = 0.3
  @State private var animationOpacity: Double = 0.0
  
  var body: some View {
    ZStack {
      Image("BoxkeyPad")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 413, height: 568)
      
      VStack {
        PasswordDisplay(inputPassword: $inputPassword)
        Spacer()
      }
      .padding(.top, 103)
      .padding(.trailing, 30)
      
      VStack {
        Spacer()
        PasswordKeypadView(inputPassword: $inputPassword)
      }
      .padding(.bottom, 105)
      .padding(.leading, 49)
      
      VStack {
        Spacer()
        BottomRow(
          inputPassword: $inputPassword,
          correctPassword: $correctPassword,
          isPresented: $isPresented,
          showError: $showError
        )
      }
      .padding(.bottom, 39)
      .padding(.leading, 43)
    }
    .frame(width: 413, height: 568)
    .scaleEffect(animationScale)
    .opacity(animationOpacity)
    .onAppear {
      withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
        animationScale = 1.0
        animationOpacity = 1.0
      }
    }
    .onDisappear {
      animationScale = 0.3
      animationOpacity = 0.0
    }
  }
  
  struct PasswordDisplay: View {
    
    @Binding var inputPassword: String
    
    var body: some View {
      HStack(alignment: .center) {
        ForEach(0..<3, id: \.self) { index in
          if index < inputPassword.count {
            Text("*")
              .font(.system(size: 90, weight: .bold))
              .foregroundStyle(.secure)
          }
        }
      }
    }
  }
  
  struct PasswordKeypadView: View {
    
    @State private var soundManager = SoundManager.shared
    @Binding var inputPassword: String
    
    private let gridColumns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 4), count: 3)
    
    var body: some View {
      LazyVGrid(columns: gridColumns, spacing: 27) {
        ForEach(1...9, id: \.self) { number in
          CustomButton(label: "\(number)", disable: false) {
            print("\(number)")
            addNumber(number)
            soundManager.playSound(.buttonTap, volume: 1.0)
          }
        }
      }
      .frame(width: 240)
    }
    private func addNumber(_ number: Int) {
      if inputPassword.count < 4 {
        inputPassword += "\(number)"
      }
    }
  }
  
  struct BottomRow: View {
    
    @State private var soundManager = SoundManager.shared
    
    @Binding var inputPassword: String
    @Binding var correctPassword: String
    @Binding var isPresented: Bool
    @Binding var showError: Bool
    
    var body: some View {
      HStack(spacing: 36) {
        CustomButton(
          label: "",
          disable: false) {
            removeLastNumber()
            soundManager.playSound(.buttonTap, volume: 1.0)
          }
        OpenCustomButton(
          label: "Open",
          disable: false,
          action: {
            checkPassword()
          }
        )
      }
    }
    private func removeLastNumber() {
      if !inputPassword.isEmpty {
        inputPassword.removeLast()
      }
    }
    private func checkPassword() {
      if inputPassword == correctPassword {
        // 성공
        isPresented = false
        showError = false
        NotificationCenter.default.post(name: NSNotification.Name("openBox"), object: nil)
        soundManager.playSound(.success, volume: 1.0)
      } else {
        // 실패
        showError = true
        inputPassword = ""
        soundManager.playSound(.fail, volume: 1.0)
      }
    }
  }
  
  private func closeModal() {
    isPresented = false
    inputPassword = ""
    showError = false
  }
}

#Preview {
  PasswordModalView(isPresented: .constant(true), inputPassword: "111")
}
