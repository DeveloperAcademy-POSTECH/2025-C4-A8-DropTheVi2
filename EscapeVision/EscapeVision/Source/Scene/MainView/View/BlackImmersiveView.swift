//
//  BlackImmersiveView.swift
//  EscapeVision
//
//  Created by Monica LEE on 7/28/25.
//

//
//  GuidlineImmersiveView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/25/25.
//

import Foundation
import RealityKit
import RealityKitContent
import SwiftUI

struct BlackImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showARTutorial: Bool = false
    @State private var blackEntity: Entity?
    @State private var rootAnchor: AnchorEntity?
    
    var body: some View {
        RealityView { content in
            let anchor = AnchorEntity(world: matrix_identity_float4x4)
            rootAnchor = anchor
            content.add(anchor)
            
            guard let blackEntity = try? await Entity(
                named: "BlackScene",
                in: realityKitContentBundle
            ) else {
                print("블랙 불러오기 실패")
                return
            }
            
            blackEntity.position = SIMD3<Float>(0, 0, -0.5)
            
            self.blackEntity = blackEntity
            anchor.addChild(blackEntity)
        }
        .onAppear {
            Task {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    appModel.startGame()
                }
            }
        }
        .onDisappear {
            cleanupGuidelineEntities()
        }
    }
    private func cleanupGuidelineEntities() {
        print("🧹 블랙 엔티티 정리 중...")
        
        if let black = blackEntity {
            black.removeFromParent()
            self.blackEntity = nil
        }
        
        rootAnchor?.children.forEach { child in
            if child.name != "startButton" && child.name != "tutorial" {
                child.removeFromParent()
            }
        }
    }
}
