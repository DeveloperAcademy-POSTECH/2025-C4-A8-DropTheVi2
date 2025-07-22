//
//  CustomButton.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/22/25.
//

import SwiftUI

struct CustomButton: View {
  
  @State private var isHovering: Bool = false
  
  var label: String
  var disable: Bool
  var action: () -> Void
  
  var body: some View {
    
    Button(action: action) {
      Text(label)
        .font(.system(size: 29))
        .fontWeight(.bold)
        .foregroundStyle(.buttonText)
        .multilineTextAlignment(.center)
        .background(
          RoundedRectangle(cornerRadius: 3, style: .continuous)
            .frame(width: 65, height: 53, alignment: .center)
            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 2)
            .foregroundStyle(Color("ButtonColor").opacity(0.1))
        )
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .frame(width: 50, height: 40)
        .onHover { hovering in
          isHovering = hovering
        }
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  CustomButton(label: "1", disable: false, action: {})
}
