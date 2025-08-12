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
    
    // 위치 추적을 위한 변수들
    @State private var currentUserPosition = SIMD3<Float>(0, 0, 0)
    @State private var targetPosition = SIMD3<Float>(0, 0, 0)
    
    // 사용자 높이 설정
    private let userHeight: Float = 1.7
    private let smoothingFactor: Float = 0.35
    
    var body: some View {
        RealityView { content in
            // 월드 앵커 생성
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
            
            // 초기 위치 설정 (사용자 현재 위치 기준)
            if let deviceTracker = deviceAnchor {
                let initialTransform = deviceTracker.transformMatrix(relativeTo: nil)
                let initialHeadPosition = SIMD3<Float>(
                    initialTransform.columns.3.x,
                    initialTransform.columns.3.y - userHeight,
                    initialTransform.columns.3.z
                )
                guideLineEntity.position = initialHeadPosition + SIMD3<Float>(0, 0, -0.5)
                currentUserPosition = guideLineEntity.position
            } else {
                guideLineEntity.position = SIMD3<Float>(0, -userHeight, -0.5)
            }
            
            self.guidelineEntity = guideLineEntity
            anchor.addChild(guideLineEntity)
            
            // 위치 업데이트 타이머 시작
            startPositionTracking()
        }
        .onDisappear {
            stopPositionTracking()
            cleanupGuidelineEntities()
        }
    }
    
    // MARK: - Position Tracking Methods
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
        
        // 헤드셋의 현재 월드 위치 가져오기
        let headWorldTransform = deviceAnchor.transformMatrix(relativeTo: nil)
        let headWorldPosition = SIMD3<Float>(
            headWorldTransform.columns.3.x,
            headWorldTransform.columns.3.y,
            headWorldTransform.columns.3.z
        )
        
        // Transform matrix에서 forward 방향 벡터 추출 (z축)
        let forward = SIMD3<Float>(
            -headWorldTransform.columns.2.x,
            0, // Y축 회전은 무시 (바닥 평면에만 관심)
            -headWorldTransform.columns.2.z
        )
        let normalizedForward = normalize(forward)
        
        // 발 위치 계산 (머리 위치에서 아래로)
        let footPosition = SIMD3<Float>(
            headWorldPosition.x,
            headWorldPosition.y - userHeight, // 바닥 높이로 조정
            headWorldPosition.z
        )
        
        // 거리 기반 적응형 보간
        let distance = length(targetPosition - currentUserPosition)
        let adaptiveSmoothingFactor: Float
        
        if distance > 0.3 {
            // 거리가 멀면 빠르게 따라옴
            adaptiveSmoothingFactor = min(0.4, smoothingFactor * 2)
        } else if distance < 0.1 {
            // 매우 가까우면 즉시 위치 고정
            adaptiveSmoothingFactor = 1.0
        } else {
            // 중간 거리에서는 부드럽게
            adaptiveSmoothingFactor = smoothingFactor
        }
        
        // 부드러운 움직임을 위한 선형 보간 (Lerp)
        currentUserPosition = lerp(
            start: currentUserPosition,
            end: targetPosition,
            t: adaptiveSmoothingFactor
        )
        
        // 가이드라인 엔티티 위치 업데이트
        guidelineEntity.position = currentUserPosition
        
        // 사용자가 바라보는 방향으로 회전 (Y축 회전만)
        let yaw = atan2(normalizedForward.x, normalizedForward.z)
        guidelineEntity.orientation = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
    }
    
    // MARK: - Helper Methods
    
    /// 선형 보간 함수
    private func lerp(start: SIMD3<Float>, end: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        return start + (end - start) * t
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
