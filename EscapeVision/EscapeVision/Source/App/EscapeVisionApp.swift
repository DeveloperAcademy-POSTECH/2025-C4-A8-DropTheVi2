//
//  EscapeTestApp.swift
//  EscapeTest
//
//  Created by 조재훈 on 7/12/25.
//

import SwiftUI

@main
struct EscapeTestApp: App {
  
  @State private var appModel = AppModel()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(appModel)
    }
    
    ImmersiveSpace(id: appModel.immersiveSpaceID) {
      RoomImmersiveView()
        .environment(appModel)
        .onAppear {
          appModel.immersiveSpaceState = .open
        }
        .onDisappear {
          appModel.immersiveSpaceState = .closed
        }
    }
    //        .immersionStyle(selection: .constant(.full), in: .full)
    // Full Mode
    // 1.5 미터 반경 제한 걸림, 방 잘림, 몰입감은 최대
    .immersionStyle(selection: .constant(.mixed), in: .mixed)
    // mixed Mode
    // 실제 방 크기만큼 확장 가능, 바닥은 passthrough, 나머지는 vr, 몰입감 살짝 깨짐
    //        .immersionStyle(selection: .constant(.progressive), in: .progressive)
    // progressive Mode
    // 몰입도 조절 가능 (0.1~1.0), FullMode 보다 더 넓은 환경, 동적 몰입도 변경 가능
  }
}
