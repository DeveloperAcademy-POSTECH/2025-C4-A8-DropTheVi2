//
//  ColorExtension.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/23/25.
//

import SwiftUI

extension Color {
  init(hex: String) {
    let scanner = Scanner(string: hex)
    _ = scanner.scanString("#")
    
    var rgb: UInt64 = 0
    scanner.scanHexInt64(&rgb)
    
    let red = Double((rgb >> 16) & 0xFF) / 255.0
    let green = Double((rgb >> 8) & 0xFF) / 255.0
    let blue = Double(rgb & 0xFF) / 255.0
    
    self.init(red: red, green: green, blue: blue)
  }
}
