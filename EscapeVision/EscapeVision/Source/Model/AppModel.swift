//
//  AppModel.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/12/25.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case waiting   // 6초 대기 상태 (기본 화면 유지)
        case loading   // 3초 검정화면 상태
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
}
