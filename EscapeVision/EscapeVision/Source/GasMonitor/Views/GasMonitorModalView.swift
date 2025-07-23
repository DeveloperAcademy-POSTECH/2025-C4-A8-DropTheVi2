
//  GasMonitorModalView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/22/25.
//

import SwiftUI

struct GasMonitorModalView: View {
  @State private var value1: Int = 0
  @State private var value2: Int = 0
  @State private var value3: Int = 0
  @State private var isActive: Bool = false
  
  // 파티클 제어를 위한 클로저
  var onParticleStateChanged: ((Bool) -> Void)?
  
  var body: some View {
    GeometryReader { geo in
      ZStack {
        if isActive {
          Image("Monitor_Active")
            .resizable()
            .scaledToFit()
        } else {
          Image("Monitor_Standby")
            .resizable()
            .scaledToFit()
        }
        
        
        // 버튼 위치 (비율 기준)
        MonitorControlView(value: $value1, onValueChanged: checkMonitorAnswer, isActive: isActive)
          .frame(width: geo.size.width * 0.35, height: geo.size.height * 0.18)
          .position(
            x: geo.size.width * 0.7148,
            y: geo.size.height * 0.305)
        MonitorControlView(value: $value2, onValueChanged: checkMonitorAnswer, isActive: isActive)
          .frame(width: geo.size.width * 0.35, height: geo.size.height * 0.18)
          .position(
            x: geo.size.width * 0.7148,
            y: geo.size.height * 0.48)
        MonitorControlView(value: $value3, onValueChanged: checkMonitorAnswer, isActive: isActive)
          .frame(width: geo.size.width * 0.35, height: geo.size.height * 0.18)
          .position(
            x: geo.size.width * 0.7148,
            y: geo.size.height * 0.655)
      }
      
      
      
    }
    .cornerRadius(20)
    .frame(width: 1920, height: 1175)
    .onChange(of: isActive) { oldValue, newValue in
      print("GasMonitorModalView: isActive 변경됨 - \(oldValue) → \(newValue)")
      // isActive 상태가 변경될 때 particle 제어
      onParticleStateChanged?(newValue)
    }
  }
  private func checkMonitorAnswer() {
    if value1 == 4 && value2 == 7 && value3 == 9 {
      isActive = true
    }
  }
  
  struct MonitorControlView: View {
    @Binding var value: Int
    var onValueChanged: () -> Void
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
              if value > 0 {
                value -= 1
                onValueChanged()
              }
            }) {
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
            }
            .buttonStyle(.plain)
            
            Button(action: {
              if value < 9 {
                value += 1
                onValueChanged()
              }
            }) {
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
            }
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
  
  
}



#Preview {
  GasMonitorModalView()
}
