//
//  ContentView.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/12/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    // 추가
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        //        ZStack {
        //            // IntroImage
        //
        //            Image("IntroImage")
        //                .resizable()
        //                .aspectRatio(contentMode: .fit)
        //                .frame(width: 1280, height: 720)
        //                .cornerRadius(46)
        //
        //            VStack {
        //
        //                //                Model3D(named: "Scene", bundle: realityKitContentBundle)
        //                //                    .padding(.bottom, 50)
        //                Spacer()
        //
        //                ToggleImmersiveSpaceButton()
        //                    .padding(.bottom, 80)
        //
        //                Text("""
        // ※ 안전을 위해 장애물이 없는 반경 약 2m 이상의 빈 공간에서 플레이하세요.
        // ※ 이 앱에는 타격음, 사이렌 등 강한 소리가 포함되어 있으니 소리에 민감하신 분은 이용 시 주의해 주세요.
        // """)
        //
        //                .font(.system(size: 17))
        //                .foregroundStyle(.white)
        //                .lineSpacing(8)
        //                .padding(.bottom, 40)
        //            }
        //            .padding()
        //        }
        ZStack {
            if appModel.immersiveSpaceState == .loading || appModel.immersiveSpaceState == .inTransition {
                // 로딩 상태일 때 검정 화면
                Color.black
                    .ignoresSafeArea()
            } else {
                // 기본 화면
                Image("IntroImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 1280, height: 720)
                    .cornerRadius(46)
                
                VStack {
                    //                Model3D(named: "Scene", bundle: realityKitContentBundle)
                    //                    .padding(.bottom, 50)
                    Spacer()
                    
                    ToggleImmersiveSpaceButton()
                        .padding(.bottom, 80)
                    
                    Text("※ 안전을 위해 장애물이 없는 반경 약 2m 이상의 빈 공간에서 플레이하세요.")
       Text("※ 이 앱에는 타격음, 사이렌 등 강한 소리가 포함되어 있으니 소리에 민감하신 분은 이용 시 주의해 주세요.")
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .lineSpacing(8)
                    .padding(.bottom, 40)
                    .frame(alignment: .center)
                }
                .padding()
            }
        }
    }
    .padding()
    .fullScreenCover(isPresented: $showARTutorial, content: {
      ARTutorial(isPresented: $showARTutorial)
    })
    .animation(.easeInOut(duration: 0.3), value: showARTutorial)
  }
}

#Preview(windowStyle: .automatic) {
  ContentView()
    .environment(AppModel())
}
