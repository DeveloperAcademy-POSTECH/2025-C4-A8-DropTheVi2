//
//  MainThemeView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/28/25.
//

import Foundation
import SwiftUI

struct MainThemeView: View {
    @Environment(AppModel.self) private var appModel
    
    @State private var showLicenses = false
    var body: some View {
        ZStack {
            Image("IntroImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(46)
                .edgesIgnoringSafeArea(.all)
            HStack(alignment: .top) {
                Spacer()
                Button(action: {
                    showLicenses.toggle()
                }, label: {
                    Text("Licenses")
                })
            }
            .padding(.trailing, 50)
            .padding(.bottom, 570)
            
            VStack {
                if appModel.appState == .menu {
                    Button(action: {
                        appModel.startLoad()
                    }, label: {
                        Text("Game Start")
                            .font(.system(size: 32, weight: .bold))
                            .padding(.vertical, 15)
                            .padding(.horizontal, 10)
                    })
                } else if appModel.appState == .loading {
                    ProgressView()
                } else if appModel.appState == .playing {
                    Button(action: {
                        appModel.exitGame()
                    }, label: {
                        Text("Exit Game")
                            .font(.system(size: 32, weight: .bold))
                            .padding(.vertical, 15)
                            .padding(.horizontal, 10)
                    })
                }
            }
            .padding(.top, 400)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showLicenses) {
            LicensesView()
                .onTapGesture {
                    showLicenses.toggle()
                }
        }
    }
}

#Preview {
    MainThemeView()
        .environment(AppModel())
}
