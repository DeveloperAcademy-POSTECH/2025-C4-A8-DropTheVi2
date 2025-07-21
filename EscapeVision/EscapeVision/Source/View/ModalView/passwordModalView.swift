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
  @State private var inputPassword = ""
  @State private var showError = false
//  @State private var isCorrected = false
  @Environment(\.dismiss) private var dismiss
  
  @State private var viewModel = RoomViewModel.shared
  
  private let correctPassword = "1234"
  
  var body: some View {
    
    VStack(spacing: 40) {
      // 헤더
      VStack(spacing: 16) {
        Image(systemName: "lock.fill")
          .font(.system(size: 60))
          .foregroundStyle(.primary)
        
        Text("비밀번호를 입력하세요")
          .font(.title)
          .fontWeight(.semibold)
      }
      
      // 비밀번호 입력 영역
      VStack(spacing: 20) {
        SecureField("비밀번호", text: $inputPassword)
          .textFieldStyle(.roundedBorder)
          .font(.title2)
          .keyboardType(.numberPad)
          .submitLabel(.done)
          .onSubmit {
            checkPassword()
          }
        
        if showError {
          Label("잘못된 비밀번호입니다", systemImage: "exclamationmark.triangle")
            .foregroundStyle(.red)
            .font(.callout)
        }
      }
      
      // 버튼 영역
      HStack(spacing: 20) {
        Button("취소") {
          closeModal()
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        
        Button("확인") {
          checkPassword()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(inputPassword.isEmpty)
      }
    }
    .padding(60)
    .frame(maxWidth: 500)
    
    .onAppear {
      inputPassword = ""
      showError = false
    }
  }
  
  private func checkPassword() {
    if inputPassword == correctPassword {
      // 성공
      isPresented = false
      showError = false
      NotificationCenter.default.post(name: NSNotification.Name("openBox"), object: nil)
    } else {
      // 실패
      showError = true
      inputPassword = ""
    }
  }
  
  private func closeModal() {
    isPresented = false
    inputPassword = ""
    showError = false
  }
}

#Preview {
  PasswordModalView(isPresented: .constant(true))
}
