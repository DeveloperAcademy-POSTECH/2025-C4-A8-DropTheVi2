//
//  MonitorControlView+.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/25/25.
//

import SwiftUI

struct MonitorControlView: View {
  var value: Int
  var onIncrease: () -> Void
  var onDecrease: () -> Void
  var isActive: Bool
  
  var body: some View {
    HStack(spacing: 10) {
      Text(String(value))
        .font(.system(size: 142, weight: .medium, design: .default))
        .foregroundStyle(Color.green00)
        .frame(minWidth: 20)
        .minimumScaleFactor(0.5)
        .padding(.top, 0)
        .padding(.trailing, 150)
      
      if !isActive {
        HStack(spacing: 42) {
          Button(action: {
            onDecrease()
          }, label: {
            RoundedRectangle(cornerRadius: 17)
              .stroke(Color.green00, lineWidth: 3)
              .overlay {
                Image(systemName: "minus")
                  .font(.system(size: 60, weight: .bold, design: .default))
                  .foregroundColor(Color.green00)
                  .scaledToFit()
                  .padding(.top, 3)
              }
              .frame(width: 130, height: 130)
          })
          .buttonStyle(.plain)
          
          Button(action: {
            onIncrease()
          }, label: {
            RoundedRectangle(cornerRadius: 17)
              .stroke(Color.green00, lineWidth: 3)
              .overlay {
                Image(systemName: "plus")
                  .font(.system(size: 60, weight: .bold, design: .default))
                  .foregroundColor(Color.green00)
                  .scaledToFit()
                  .padding(.top, 3)
              }
              .frame(width: 130, height: 130)
          })
          .buttonStyle(.plain)
        }
      } else {
        HStack(spacing: 42) {
          RoundedRectangle(cornerRadius: 17)
            .opacity(0)
            .frame(width: 130, height: 130)
          
          RoundedRectangle(cornerRadius: 17)
            .opacity(0)
            .frame(width: 130, height: 130)
        }
      }
    }
  }
}
