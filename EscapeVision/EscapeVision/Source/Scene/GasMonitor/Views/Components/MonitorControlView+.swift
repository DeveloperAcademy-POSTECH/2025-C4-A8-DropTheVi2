//
//  MonitorControlView+.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/25/25.
//

import SwiftUI

struct MonitorControlView: View {
  @State private var soundManager = SoundManager.shared
  
  var value: Int
  var onIncrease: () -> Void
  var onDecrease: () -> Void
  var isActive: Bool
  var scaleFactor: CGFloat = 1.0 // 기본값 1.0으로 설정
  
  // 기준 크기들 (1920x1175 기준)
  private let baseFontSize: CGFloat = 142
  private let baseButtonSize: CGFloat = 130
  private let baseButtonFontSize: CGFloat = 60
  private let baseHorizontalSpacing: CGFloat = 20
  private let baseButtonSpacing: CGFloat = 42
  private let basePadding: CGFloat = 150
  private let baseCornerRadius: CGFloat = 17
  private let baseLineWidth: CGFloat = 3
  private let baseMinWidth: CGFloat = 20
  private let baseTopPadding: CGFloat = 3
  
  private let baseTextWidth: CGFloat = 213
  
  var body: some View {
    // 스케일된 값들 계산
    let scaledFontSize = baseFontSize * scaleFactor
    let scaledButtonSize = baseButtonSize * scaleFactor
    let scaledButtonFontSize = baseButtonFontSize * scaleFactor
    let scaledHorizontalSpacing = baseHorizontalSpacing * scaleFactor
    let scaledButtonSpacing = baseButtonSpacing * scaleFactor
    let scaledPadding = basePadding * scaleFactor
    let scaledCornerRadius = baseCornerRadius * scaleFactor
    let scaledLineWidth = baseLineWidth * scaleFactor
    let scaledTextWidth = baseTextWidth * scaleFactor
    
    HStack(spacing: scaledHorizontalSpacing) {
      Text(String(value))
        .font(.system(size: scaledFontSize, weight: .medium, design: .default))
        .foregroundStyle(Color.green00)
        .frame(width: scaledTextWidth, alignment: .trailing)
        .padding(.top, 0)
        .padding(.trailing, scaledPadding)

      if !isActive {
        HStack(spacing: scaledButtonSpacing) {
          Button(action: {
            onDecrease()
            soundManager.playSound(.monitorTap, volume: 1.0)
          }, label: {
            ZStack {
              RoundedRectangle(cornerRadius: scaledCornerRadius)
                .stroke(Color.green00, lineWidth: scaledLineWidth)
              
              Image(systemName: "minus")
                .font(.system(size: scaledButtonFontSize, weight: .bold, design: .default))
                .foregroundColor(Color.green00)
            }
            .frame(width: scaledButtonSize, height: scaledButtonSize)
          })
          .buttonStyle(.plain)
          
          Button(action: {
            onIncrease()
            soundManager.playSound(.monitorTap, volume: 1.0)
          }, label: {
            ZStack {
              RoundedRectangle(cornerRadius: scaledCornerRadius)
                .stroke(Color.green00, lineWidth: scaledLineWidth)
              
              Image(systemName: "plus")
                .font(.system(size: scaledButtonFontSize, weight: .bold, design: .default))
                .foregroundColor(Color.green00)
            }
            .frame(width: scaledButtonSize, height: scaledButtonSize)
          })
          .buttonStyle(.plain)
        }
      } else {
        HStack(spacing: scaledButtonSpacing) {
          RoundedRectangle(cornerRadius: scaledCornerRadius)
            .opacity(0)
            .frame(width: scaledButtonSize, height: scaledButtonSize)
          
          RoundedRectangle(cornerRadius: scaledCornerRadius)
            .opacity(0)
            .frame(width: scaledButtonSize, height: scaledButtonSize)
        }
      }
    }
  }
}

#Preview {
  GasMonitorView(
      viewModel: GasMonitorViewModel(),
      onParticleStateChanged: { isActive in
          print("Particle State Changed: \(isActive)")
      }
  )
}
