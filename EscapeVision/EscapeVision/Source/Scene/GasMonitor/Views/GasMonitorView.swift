//  GasMonitorView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/22/25.
//

import Foundation
import SwiftUI

struct GasMonitorView: View {
  @State private var soundManager = SoundManager.shared
  @ObservedObject var viewModel = GasMonitorViewModel.shared
  
  // 파티클 제어를 위한 클로저
  var onParticleStateChanged: ((Bool) -> Void)?
  @State private var monitorViewOpacity = 0.0
  
  // 기본 비율 (1920:1175) 및 기준 크기
  private let aspectRatio: CGFloat = 1920.0 / 1175.0
  private let baseWidth: CGFloat = 1920.0
  private let baseHeight: CGFloat = 1175.0
  
  var body: some View {
    GeometryReader { geo in
      let scaleFactor = min(geo.size.width / baseWidth, geo.size.height / baseHeight)
      
      ZStack {
        if viewModel.isActive {
          Image("Monitor_Active")
            .resizable()
            .scaledToFit()
        } else {
          Image("Monitor_Standby")
            .resizable()
            .scaledToFit()
        }
        
        let controlData: [MonitorControlData] = [
          .init(id: 1, value: viewModel.value1, yRatio: 0.305),
          .init(id: 2, value: viewModel.value2, yRatio: 0.48),
          .init(id: 3, value: viewModel.value3, yRatio: 0.655)
        ]
        
        ForEach(controlData) { item in
          MonitorControlView(
            value: item.value,
            onIncrease: { viewModel.increaseValue(index: item.id) },
            onDecrease: { viewModel.decreaseValue(index: item.id) },
            isActive: viewModel.isActive,
            scaleFactor: scaleFactor // 스케일 팩터 전달
          )
          .frame(
            width: geo.size.width * 0.35,
            height: geo.size.height * 0.18
          )
          .position(
            x: geo.size.width * 0.7148,
            y: geo.size.height * item.yRatio
          )
        }
      }
    }
    .opacity(monitorViewOpacity)
    .onAppear {
      // Fade in 애니메이션
      withAnimation(.easeIn(duration: 0.6)) {
        monitorViewOpacity = 1.0
      }
    }
    .onDisappear {
      withAnimation(.easeInOut(duration: 0.6)) {
        monitorViewOpacity = 0.0
      }
    }
    .aspectRatio(aspectRatio, contentMode: .fit)
    .cornerRadius(20)
    .onChange(of: viewModel.isActive) { oldValue, newValue in
      print("GasMonitorView: isActive 변경됨 - \(oldValue) → \(newValue)")
      onParticleStateChanged?(newValue)
        soundManager.playSound(.monitorsuccess, volume: 3.0)
    }
  }
}

struct MonitorControlData: Identifiable {
  let id: Int
  let value: Int
  let yRatio: CGFloat
}

#Preview {
    GasMonitorView(
        viewModel: GasMonitorViewModel(),
        onParticleStateChanged: { isActive in
            print("Particle State Changed: \(isActive)")
        }
    )
}
