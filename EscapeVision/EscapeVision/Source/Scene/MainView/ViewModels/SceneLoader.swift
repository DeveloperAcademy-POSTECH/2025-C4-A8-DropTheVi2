//
//  SceneLoader.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor
final class SceneLoader {
  static let shared = SceneLoader()
  private init() {}
  
  // MARK: - Public Interface
  
  func loadRoom(into anchor: AnchorEntity) async {
    print("🏠 === Room 씬 로딩 시작 ===")
    
    // Room을 포함한 씬들을 우선순위대로 시도
    let roomSceneNames = [
      "TestScene",     // Room.usdz를 참조하는 씬 (최우선)
      "Room",          // Room.usdz 직접 로드
      "Scene",         // 대체 씬
      "Immersive",     // Immersive 씬
      "Content"        // Content 씬
    ]
    
    var loadedEntity: Entity?
    var usedSceneName: String?
    var lastError: Error?
    
    for sceneName in roomSceneNames {
      print("🔄 '\(sceneName)' 씬 로드 시도 중...")
      
      do {
        let entity = try await Entity(named: sceneName, in: realityKitContentBundle)
        loadedEntity = entity
        usedSceneName = sceneName
        print("✅ '\(sceneName)' 씬 로드 성공!")
        
        // Room 관련 씬이 로드되면 구조 분석
        print("📊 엔티티 이름: \(entity.name)")
        print("📊 자식 수: \(entity.children.count)")
        analyzeEntityStructureDeep(entity, depth: 0, maxDepth: 3)
        break
        
      } catch {
        print("❌ '\(sceneName)' 씬 로드 실패: \(error)")
        print("   상세 오류: \(error.localizedDescription)")
        if let nsError = error as NSError? {
          print("   오류 코드: \(nsError.code)")
          print("   오류 도메인: \(nsError.domain)")
        }
        lastError = error
      }
    }
    
    // 로드된 씬이 있는 경우
    if let loadedEntity = loadedEntity {
      print("🔍 === 로드된 씬 최종 분석 ===")
      print("📊 사용된 씬 이름: \(usedSceneName ?? "알 수 없음")")
      print("📊 엔티티 이름: \(loadedEntity.name)")
      print("📊 자식 수: \(loadedEntity.children.count)")
      
      // Box 엔티티 설정
      if let boxTest = loadedEntity.findEntity(named: "Box") {
        EntityUtilities.setUpLockEntity(in: boxTest)
        print("박스 설정 성공")
      } else {
        print("테스트 박스 설정 실패")
      }
      
      anchor.addChild(loadedEntity)
      print("🏠 씬 로딩 및 설정 완료")
      return
    }
    
    // 모든 로드가 실패한 경우
    print("❌ 모든 씬 로드 실패")
    if let lastError = lastError {
      print("🔍 마지막 오류 상세:")
      print("   오류: \(lastError)")
      print("   설명: \(lastError.localizedDescription)")
      if let nsError = lastError as NSError? {
        print("   코드: \(nsError.code), 도메인: \(nsError.domain)")
      }
    }
    print("🚧 대체 씬 생성으로 전환")
    createFallbackScene(into: anchor)
  }
  
  func loadObject(into anchor: AnchorEntity) async {
    guard let clipBoard = try? await ModelEntity(named: "Clipboard") else {
      print("클립보드 불러오기 실패")
      return
    }
    
    clipBoard.position = SIMD3<Float>(1.04585, 0.85956, 1.1323)
    EntityUtilities.setDragEntity(clipBoard, name: "Clipboard")
    anchor.addChild(clipBoard)
  }
  
  // MARK: - Private Methods
  
  /// 대체 씬 생성 (모든 로드가 실패한 경우)
  private func createFallbackScene(into anchor: AnchorEntity) {
    print("🚧 대체 씬 생성 중...")
    
    // 기본 바닥 생성
    let floorMaterial = SimpleMaterial(color: .lightGray, isMetallic: false)
    let floor = ModelEntity(
      mesh: .generateBox(size: [10, 0.1, 10]),
      materials: [floorMaterial]
    )
    floor.name = "FallbackFloor"
    floor.position = SIMD3<Float>(0, -0.05, 0)
    
    // 물리 컴포넌트 추가
    floor.components.set(PhysicsBodyComponent(
      massProperties: .default,
      material: .default,
      mode: .static
    ))
    floor.generateCollisionShapes(recursive: true)
    
    anchor.addChild(floor)
    
    print("✅ 대체 씬 생성 완료 (기본 바닥)")
  }
  
  /// 엔티티 구조를 깊이 있게 분석하는 함수
  private func analyzeEntityStructureDeep(_ entity: Entity, depth: Int, maxDepth: Int) {
    let indent = String(repeating: "  ", count: depth)
    let typeInfo = type(of: entity)
    print("\(indent)📋 \(entity.name) (타입: \(typeInfo))")
    print("\(indent)   - 위치: \(entity.position)")
    print("\(indent)   - 자식 수: \(entity.children.count)")
    
    // 컴포넌트 정보도 출력
    if !entity.components.isEmpty {
      print("\(indent)   - 컴포넌트: \(entity.components.count)개")
    }
    
    // 최대 깊이 제한
    if depth < maxDepth && !entity.children.isEmpty {
      for (index, child) in entity.children.enumerated() {
        print("\(indent)   자식 \(index):")
        analyzeEntityStructureDeep(child, depth: depth + 1, maxDepth: maxDepth)
      }
    }
  }
} 