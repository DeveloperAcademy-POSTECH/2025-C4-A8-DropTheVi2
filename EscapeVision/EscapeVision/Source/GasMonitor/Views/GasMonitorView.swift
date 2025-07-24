//  GasMonitorModalView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/22/25.
//

import Foundation
import SwiftUI

struct GasMonitorView: View {
  @ObservedObject var viewModel = GasMonitorViewModel.shared
  
  // 파티클 제어를 위한 클로저
  var onParticleStateChanged: ((Bool) -> Void)?
  
  var body: some View {
    GeometryReader { geo in
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
            isActive: viewModel.isActive
          )
          .frame(
            width: geo.size.width * 0.35, height: geo.size.height * 0.18
          )
          .position(
            x: geo.size.width * 0.7148,
            y: geo.size.height * item.yRatio
          )
        }
      }
    }
    .cornerRadius(20)
    .frame(width: 1920, height: 1175)
    .onChange(of: viewModel.isActive) { oldValue, newValue in
      print("GasMonitorView: isActive 변경됨 - \(oldValue) → \(newValue)")
      onParticleStateChanged?(newValue)
    }
  }
}

struct MonitorControlData: Identifiable {
  let id: Int
  let value: Int
  let yRatio: CGFloat
}

#Preview {
  GasMonitorView()
}
