//
//  ToggleImmersiveSpaceButton.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/12/25.
//

import SwiftUI

struct ToggleImmersiveSpaceButton: View {
    
    @Environment(AppModel.self) private var appModel
    
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    var body: some View {
        Button {
            //            Task { @MainActor in
            //                switch appModel.immersiveSpaceState {
            //                case .open:
            //                    appModel.immersiveSpaceState = .inTransition
            //                    await dismissImmersiveSpace()
            //                    // Don't set immersiveSpaceState to .closed because there
            //                    // are multiple paths to ImmersiveView.onDisappear().
            //                    // Only set .closed in ImmersiveView.onDisappear().
            //
            //                case .closed:
            //                    appModel.immersiveSpaceState = .inTransition
            //                    switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
            //                    case .opened:
            //                        // Don't set immersiveSpaceState to .open because there
            //                        // may be multiple paths to ImmersiveView.onAppear().
            //                        // Only set .open in ImmersiveView.onAppear().
            //                        break
            //
            //                    case .userCancelled, .error:
            //                        // On error, we need to mark the immersive space
            //                        // as closed because it failed to open.
            //                        fallthrough
            //                    @unknown default:
            //                        // On unknown response, assume space did not open.
            //                        appModel.immersiveSpaceState = .closed
            //                    }
            //
            //                case .inTransition:
            //                    // This case should not ever happen because button is disabled for this case.
            //                    break
            Task { @MainActor in
                switch appModel.immersiveSpaceState {
                case .open:
                    appModel.immersiveSpaceState = .inTransition
                    await dismissImmersiveSpace()
                    
                case .closed:
                    // 6초 대기 상태로 먼저 변경
                    appModel.immersiveSpaceState = .waiting
                    
                    // 6초 대기
                    try? await Task.sleep(nanoseconds: 6_000_000_000)
                    
                    // 검정화면 로딩 상태로 변경
                    appModel.immersiveSpaceState = .loading
                    
                    // 3초 더 대기
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    
                    // 실제 Immersive Space 열기
                    appModel.immersiveSpaceState = .inTransition
                    switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                    case .opened:
                        break
                        
                    case .userCancelled, .error:
                        fallthrough
                    @unknown default:
                        appModel.immersiveSpaceState = .closed
                    }
                    
                case .inTransition, .loading, .waiting:
                    break
                }
            }
        }
        label: {
            Text(appModel.immersiveSpaceState == .open ? "Restart" : "Game Start")
                .foregroundColor(.white)
                .frame(width: 280, height: 52)
                .fontWeight(.semibold)
                .font(.system(size: 19))
        }
        
        .cornerRadius(30)
        .disabled(appModel.immersiveSpaceState == .inTransition)
    }
}
