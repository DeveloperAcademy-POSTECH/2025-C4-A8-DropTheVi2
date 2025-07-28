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

struct GuidelineImmersiveView: View {
  @Environment(AppModel.self) private var appModel
  @State private var showARTutorial: Bool = false
  @State private var guidelineEntity: Entity?
  @State private var rootAnchor: AnchorEntity?
  
  var body: some View {
    RealityView { content in
      let anchor = AnchorEntity(world: matrix_identity_float4x4)
      rootAnchor = anchor
      content.add(anchor)
      
      guard let guideLineEntity = try? await Entity(
        named: "GuidelineScene",
        in: realityKitContentBundle
      ) else {
        print("가이드라인 불러오기 실패")
        return
      }
      
      guideLineEntity.position = SIMD3<Float>(0, 0, -0.5)
      
      self.guidelineEntity = guideLineEntity
      anchor.addChild(guideLineEntity)
    }
    .onDisappear {
      cleanupGuidelineEntities()
    }
  }
  private func cleanupGuidelineEntities() {
    print("🧹 가이드라인 엔티티 정리 중...")
    
    if let guideline = guidelineEntity {
      guideline.removeFromParent()
      self.guidelineEntity = nil
    }
    
    rootAnchor?.children.forEach { child in
      if child.name != "startButton" && child.name != "tutorial" {
        child.removeFromParent()
      }
    }
  }
}
