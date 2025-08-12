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
import ARKit

struct GuidelineImmersiveView2: View {
    @Environment(AppModel.self) private var appModel
    @State private var showARTutorial: Bool = false
    @State private var guidelineEntity: Entity?
    @State private var rootAnchor: AnchorEntity?
    @State private var deviceAnchor: AnchorEntity?
    @State private var updateTimer: Timer?
    
    // 사용자 높이 설정
    private let userHeight: Float = 1.7 // 머리에서 바닥까지의 대략적인 높이
    
    // 스케일 보정 계수
    private let scaleCorrection: Float = 32.5
    
    var body: some View {
        RealityView { content in
            // 월드 앵커 생성 (고정 기준점)
            let anchor = AnchorEntity(world: matrix_identity_float4x4)
            rootAnchor = anchor
            content.add(anchor)
            
            // 디바이스 추적을 위한 앵커 생성 (헤드셋 위치 추적)
            let deviceTracker = AnchorEntity(.head)
            deviceAnchor = deviceTracker
            content.add(deviceTracker)
            
            // 가이드라인 엔티티 로드
            guard let guideLineEntity = try? await Entity(
                named: "GuidelineScene",
                in: realityKitContentBundle
            ) else {
                print("가이드라인 불러오기 실패")
                return
            }
            
            // 초기 위치 설정
            guideLineEntity.position = SIMD3<Float>(0, -userHeight, 0)
            
            self.guidelineEntity = guideLineEntity
            
            // world 좌표계를 직접 사용
            let worldAnchor = AnchorEntity(world: matrix_identity_float4x4)
            worldAnchor.addChild(guideLineEntity)
            content.add(worldAnchor)
            
            // 위치 업데이트 타이머 시작
            startPositionTracking()
        }
        .onDisappear {
            stopPositionTracking()
            cleanupGuidelineEntities()
        }
    }
    
    // MARK: - Position Tracking Methods (실시간 위치 동기화)
    private func startPositionTracking() {
        // 60Hz로 업데이트 (약 16ms마다)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            updateGuidelinePosition()
        }
    }
    
    private func stopPositionTracking() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateGuidelinePosition() {
        guard let deviceAnchor = deviceAnchor,
              let guidelineEntity = guidelineEntity else { return }
        
        // World 좌표계 직접 사용
        let headWorldTransform = deviceAnchor.transformMatrix(relativeTo: nil)
        
        // 헤드셋의 world 좌표 추출
        let headWorldPosition = SIMD3<Float>(
            headWorldTransform.columns.3.x,
            headWorldTransform.columns.3.y,
            headWorldTransform.columns.3.z
        )
        
        // Transform matrix에서 forward 방향 벡터 추출
        let forward = SIMD3<Float>(
            -headWorldTransform.columns.2.x,
            0,
            -headWorldTransform.columns.2.z
        )
        let normalizedForward = normalize(forward)
        
        // 발 위치 계산 - World 좌표계에서 직접 계산
        let exactFootPosition = SIMD3<Float>(
            headWorldPosition.x,
            headWorldPosition.y - userHeight,
            headWorldPosition.z
        )
        
        // 스케일 보정 적용
        let correctedPosition = SIMD3<Float>(
            exactFootPosition.x * scaleCorrection,
            exactFootPosition.y,
            exactFootPosition.z * scaleCorrection
        )
        
        // World Transform 직접 설정 (position 대신)
        var newTransform = matrix_identity_float4x4
        newTransform.columns.3.x = correctedPosition.x  // 보정된 X 위치
        newTransform.columns.3.y = correctedPosition.y  // Y는 그대로
        newTransform.columns.3.z = correctedPosition.z  // 보정된 Z 위치
        newTransform.columns.3.w = 1.0
        
        // Y축 회전 적용
        let yaw = atan2(normalizedForward.x, normalizedForward.z)
        let rotation = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
        let rotationMatrix = float4x4(rotation)
        newTransform *= rotationMatrix
        
        // Transform 직접 설정
        guidelineEntity.transform = Transform(matrix: newTransform)
    }
    
    private func cleanupGuidelineEntities() {
        print("🧹 가이드라인 엔티티 정리 중...")
        
        stopPositionTracking()
        
        if let guideline = guidelineEntity {
            guideline.removeFromParent()
        }
        
        self.guidelineEntity = nil
        self.deviceAnchor = nil
        
        rootAnchor?.children.forEach { child in
            if child.name != "startButton" && child.name != "tutorial" {
                child.removeFromParent()
            }
        }
    }
}

#Preview {
    GuidelineImmersiveView2()
        .environment(AppModel())
}
