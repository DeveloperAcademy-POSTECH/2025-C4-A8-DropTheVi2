//
//  LicensesView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/22/25.
//

import SwiftUI

struct LicensesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Licenses")
                    .font(.title)
                    .bold()
                    .padding(.bottom, 10)

                VStack(alignment: .leading, spacing: 8) {
                    Text("📄 Archivo Narrow")
                        .font(.headline)

                    Text("""
This app uses the Archivo Narrow font from Google Fonts.

• Font: Archivo Narrow
• Copyright: Google Fonts  
• License: SIL Open Font License 1.1  
• Website: https://fonts.google.com/specimen/Archivo+Narrow

The font is licensed under the SIL Open Font License (OFL).  
""")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
          
          VStack(alignment: .leading, spacing: 16) {
              VStack(alignment: .leading, spacing: 8) {
                  Text("📄 Inter")
                      .font(.headline)

                  Text("""
This app uses the Inter font from Google Fonts.

• Font: Inter  
• Copyright: Google Fonts  
• License: SIL Open Font License 1.1  
• Website: https://fonts.google.com/specimen/Inter

The font is licensed under the SIL Open Font License (OFL).  
""")
                      .font(.body)
                      .foregroundColor(.secondary)
              }

              Spacer()
          }
          .padding()
        }
        .padding(20)
        .navigationTitle("Licenses")
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect()
    }
}

#Preview {
    LicensesView()
}
