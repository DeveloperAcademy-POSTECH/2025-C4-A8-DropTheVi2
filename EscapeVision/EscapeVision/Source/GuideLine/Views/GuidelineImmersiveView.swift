//
//  GuidlineImmersiveView.swift
//  EscapeVision
//
//  Created by PenguinLand on 7/25/25.
//

import RealityKit
import RealityKitContent
import SwiftUI
import ARKit
import Combine

struct GuidelineImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @State private var guidelineEntity: Entity?
    @State private var floorAnchor: AnchorEntity?
    @State private var arKitSession: ARKitSession?
    @State private var worldInfo: WorldTrackingProvider?
    @State private var sceneUpdateSubscription: Cancellable?
    
    var body: some View {
        RealityView { content in
            await setupARKit()
            await setupScene(content: content)
            setupSceneUpdates(content: content)
        }
        .onDisappear {
            sceneUpdateSubscription?.cancel()
            arKitSession?.stop()
        }
    }
    
    private func setupARKit() async {
        // ARKit 세션 초기화
        let session = ARKitSession()
        let worldProvider = WorldTrackingProvider()
        
        do {
            try await session.run([worldProvider])
            arKitSession = session
            worldInfo = worldProvider
        } catch {
            print("ARKit 세션 시작 실패: \(error)")
        }
    }
    
    private func setupScene(content: RealityViewContent) async {
        // 바닥 앵커 생성
        let floor = AnchorEntity(plane: .horizontal, classification: .floor)
        content.add(floor)
        floorAnchor = floor
        
        // GuidelineScene 엔티티 로드
        if let guideline = try? await Entity(named: "GuidelineScene", in: realityKitContentBundle) {
            content.add(guideline)
            guidelineEntity = guideline
            
            // 초기 설정
            guideline.transform.translation.z = -1.0
            guideline.transform.rotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
            
            print("GuidelineScene 로드 완료")
        }
    }
    
    private func setupSceneUpdates(content: RealityViewContent) {
        // SceneEvents.Update를 구독하여 매 프레임 업데이트
        sceneUpdateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
            updateGuidelinePosition()
        } as? any Cancellable
    }
    
    private func updateGuidelinePosition() {
        guard let guideline = guidelineEntity,
              let floorAnchor = floorAnchor,
              let worldInfo = worldInfo else { return }
        
        // 바닥 높이 가져오기
        let floorHeight = floorAnchor.position(relativeTo: nil).y
        
        // 사용자 머리 위치 가져오기 (DeviceAnchor 사용)
        guard let deviceAnchor = worldInfo.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            return
        }
        
        let transform = deviceAnchor.originFromAnchorTransform
        
        // 머리의 X, Z 좌표 추출 (transform의 4번째 열이 position)
        let headPosition = transform.translation
        
        // GuidelineEntity 위치 업데이트
        // X, Z: 머리 위치 따라가기
        // Y: 바닥 높이로 고정
        // Rotation: 0으로 고정
        guideline.transform.translation = SIMD3<Float>(
            headPosition.x,
            floorHeight,
            headPosition.z
        )
        guideline.transform.rotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    }
}

// simd_float4x4의 translation 추출을 위한 extension
extension simd_float4x4 {
    var translation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

#Preview {
    GuidelineImmersiveView()
        .environment(AppModel())
}
