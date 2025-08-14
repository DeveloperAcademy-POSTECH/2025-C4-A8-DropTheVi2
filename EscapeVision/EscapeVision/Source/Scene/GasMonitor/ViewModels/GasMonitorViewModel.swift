//
//  GasMonitorViewModel.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/25/25.
//
import Foundation
import SwiftUI

final class GasMonitorViewModel: ObservableObject {
  static let shared = GasMonitorViewModel()
  
  @Published var value1: Int = 0
  @Published var value2: Int = 0
  @Published var value3: Int = 0
  @Published var isActive: Bool = false
  
  @State private var soundManager = SoundManager.shared
  
  private func checkAnswer() {
    if value1 == 4 && value2 == 7 && value3 == 9 {
      isActive = true
      soundManager.pauseLocalizedWarningSound()
    }
  }
  
  func increaseValue(index: Int) {
    switch index {
    case 1:
      if value1 < 9 {
        value1 += 1
      }
    case 2:
      if value2 < 9 {
        value2 += 1
      }
    case 3:
      if value3 < 9 {
        value3 += 1
      }
    default:
      break
    }
    checkAnswer()
  }
  
  func decreaseValue(index: Int) {
    switch index {
    case 1:
      if value1 > 0 {
        value1 -= 1
      }
    case 2:
      if value2 > 0 {
        value2 -= 1
      }
    case 3:
      if value3 > 0 {
        value3 -= 1
      }
    default:
      break
    }
    checkAnswer()
  }
}
