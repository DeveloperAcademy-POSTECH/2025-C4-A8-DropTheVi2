//
//  LicensesView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/22/25.
//

import SwiftUI

// MARK: - Models
struct LicenseInfo {
  let emoji: String
  let name: String
  let copyright: String
  let license: String
  let website: String
  
  var description: String {
        """
        This app uses the \(name) font from Google Fonts.
        
        • Font: \(name)
        • Copyright: \(copyright)
        • License: \(license)
        • Website: \(website)
        
        The font is licensed under the SIL Open Font License (OFL).
        """
  }
}

// MARK: - License Data
extension LicenseInfo {
  static let licenses: [LicenseInfo] = [
    LicenseInfo(
      emoji: "📄",
      name: "Archivo Narrow",
      copyright: "Google Fonts",
      license: "SIL Open Font License 1.1",
      website: "https://fonts.google.com/specimen/Archivo+Narrow"
    ),
    LicenseInfo(
      emoji: "📄",
      name: "Inter",
      copyright: "Google Fonts",
      license: "SIL Open Font License 1.1",
      website: "https://fonts.google.com/specimen/Inter"
    )
  ]
}

// MARK: - License Item View
struct LicenseItemView: View {
  let license: LicenseInfo
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("\(license.emoji) \(license.name)")
        .font(.headline)
      
      Text(license.description)
        .font(.body)
        .foregroundColor(.secondary)
    }
  }
}

// MARK: - Main Licenses View
struct LicensesView: View {
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 24) {
          ForEach(LicenseInfo.licenses.indices, id: \.self) { index in
            LicenseItemView(license: LicenseInfo.licenses[index])
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
      }
      .navigationTitle("Licenses")
      .navigationBarTitleDisplayMode(.large)
    }
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    .glassBackgroundEffect()
  }
}

// MARK: - Preview
#Preview {
  LicensesView()
}
