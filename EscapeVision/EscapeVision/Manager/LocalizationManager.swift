//
//  LocalizationManager.swift
//  EscapeVision
//
//  Created by Assistant on 1/31/25.
//

import Foundation
import RealityKit
import UIKit

/// 언어별 RealityKit 엔티티 활성화/비활성화 및 텍스처 변경을 관리하는 매니저
@MainActor
final class LocalizationManager {
    static let shared = LocalizationManager()
    
    // 현재 언어를 저장하는 프로퍼티
    private(set) var currentLanguage: Language = .korean
    
    enum Language: String {
        case korean = "ko"
        case english = "en"
        case spanish = "es"
    }
    
    // 언어별 이미지 에셋 이름
    private let boardImageNames = [
        Language.korean: "Board_kor",
        Language.english: "Board_eng",
        Language.spanish: "Board_esp"
    ]
    
    // A06 카드 언어별 이미지 에셋 이름
    private let a06CardImageNames = [
        Language.korean: "A06Card_kor",
        Language.english: "A06Card_eng",
        Language.spanish: "A06Card_esp"
    ]
    
    // A07 카드 언어별 이미지 에셋 이름
    private let a07CardImageNames = [
        Language.korean: "A07Card_kor",
        Language.english: "A07Card_eng",
        Language.spanish: "A07Card_esp"
    ]
    
    private init() {
        detectCurrentLanguage()
    }
    
    /// 현재 시스템 언어 감지
    private func detectCurrentLanguage() {
        // 시스템의 선호 언어 가져오기
        if let preferredLanguage = Locale.preferredLanguages.first {
            print("🌐 [LocalizationManager] 감지된 언어: \(preferredLanguage)")
            
            // 언어 코드 추출 (예: "ko-KR" -> "ko")
            let languageCode = preferredLanguage.prefix(2).lowercased()
            
            switch languageCode {
            case "ko":
                currentLanguage = .korean
            case "es":
                currentLanguage = .spanish
            default:
                // 기타 언어는 영어로 처리
                currentLanguage = .english
            }
        } else {
            // 기본값은 영어
            currentLanguage = .english
        }
        
        print("🌐 [LocalizationManager] 현재 언어 설정: \(currentLanguage.rawValue)")
    }
    
    /// RealityKit 씬의 언어별 엔티티 설정 (텍스처 변경 방식)
    /// - Parameter rootEntity: 씬의 루트 엔티티
    func configureLocalizedEntities(in rootEntity: Entity) {
        print("🌐 === 언어별 엔티티 설정 시작 ===")
        print("🌐 현재 언어: \(currentLanguage.rawValue)")
        
        // 1. Board 엔티티 처리
        configureBoardEntity(in: rootEntity)
        
        // 2. A06 카드 엔티티 처리
        configureA06CardEntity(in: rootEntity)
        
        // 3. A07 카드 엔티티 처리
        configureA07CardEntity(in: rootEntity)
        
        print("🌐 === 언어별 엔티티 설정 완료 ===")
    }
    
    /// Board 엔티티 설정
    private func configureBoardEntity(in rootEntity: Entity) {
        print("🎯 Board 엔티티 설정 시작")
        
        // Board 엔티티 찾기 - Board1이 확실함
        var boardEntity: Entity?
        
        // Board1 먼저 시도 (Final.usda에 확인됨)
        if let board1 = rootEntity.findEntity(named: "Board1") {
            boardEntity = board1
            print("🌐 Board1 엔티티 발견")
        } else {
            // 다른 가능한 이름들로 시도
            let possibleBoardNames = ["Board", "Board_1", "Cork_Board", "CorkBoard"]
            for boardName in possibleBoardNames {
                if let found = rootEntity.findEntity(named: boardName) {
                    boardEntity = found
                    print("🌐 Board 엔티티 발견: \(boardName)")
                    break
                }
            }
        }
        
        // Board 엔티티가 없으면 재귀적으로 검색
        if boardEntity == nil {
            boardEntity = findBoardEntityRecursively(in: rootEntity)
        }
        
        if let board = boardEntity {
            updateBoardTexture(board)
        } else {
            print("⚠️ Board 엔티티를 찾을 수 없음")
        }
    }
    
    /// A06 카드 엔티티 설정
    private func configureA06CardEntity(in rootEntity: Entity) {
        print("🎯 A06 카드 엔티티 설정 시작")
        
        // /Root/RoomScene/A06/A06Card/Cube_010 경로로 찾기
        var targetEntity: Entity?
        
        // RoomScene 찾기
        if let roomScene = rootEntity.findEntity(named: "RoomScene") {
            print("✅ RoomScene 발견")
            
            // A06 찾기
            if let a06 = roomScene.findEntity(named: "A06") {
                print("✅ A06 발견")
                
                // A06Card 찾기
                if let a06Card = a06.findEntity(named: "A06Card") {
                    print("✅ A06Card 발견")
                    
                    // Cube_010 찾기
                    if let cube010 = a06Card.findEntity(named: "Cube_010") {
                        targetEntity = cube010
                        print("✅ Cube_010 발견 (전체 경로: /Root/RoomScene/A06/A06Card/Cube_010)")
                    } else {
                        print("⚠️ Cube_010을 찾을 수 없음")
                        // Cube로 시작하는 다른 엔티티 찾기
                        for child in a06Card.children {
                            if child.name.starts(with: "Cube") {
                                targetEntity = child
                                print("✅ 대체 Cube 엔티티 발견: \(child.name)")
                                break
                            }
                        }
                    }
                } else {
                    print("⚠️ A06Card를 찾을 수 없음")
                }
            } else {
                print("⚠️ A06을 찾을 수 없음")
            }
        } else {
            print("⚠️ RoomScene을 찾을 수 없음")
        }
        
        if let target = targetEntity {
            updateA06CardTexture(target)
        } else {
            print("⚠️ A06 카드 텍스처 대상을 찾을 수 없음")
        }
    }
    
    /// Board 엔티티를 재귀적으로 검색
    private func findBoardEntityRecursively(in entity: Entity, depth: Int = 0, maxDepth: Int = 5) -> Entity? {
        guard depth < maxDepth else { return nil }
        
        // 현재 엔티티 이름에 "board"가 포함되어 있는지 확인 (대소문자 무시)
        if entity.name.lowercased().contains("board") {
            print("🌐 Board 엔티티 발견 (재귀 검색): \(entity.name)")
            return entity
        }
        
        // 자식 엔티티들을 재귀적으로 검색
        for child in entity.children {
            if let found = findBoardEntityRecursively(in: child, depth: depth + 1, maxDepth: maxDepth) {
                return found
            }
        }
        
        return nil
    }
    
    /// Board 엔티티의 텍스처 업데이트
    private func updateBoardTexture(_ boardEntity: Entity) {
        print("🎨 Board 텍스처 업데이트 시작")
        updateEntityTexture(boardEntity, imageNames: boardImageNames, entityName: "Board")
    }
    
    /// A06 카드 엔티티의 텍스처 업데이트
    private func updateA06CardTexture(_ a06Entity: Entity) {
        print("🎨 A06 카드 텍스처 업데이트 시작")
        updateEntityTexture(a06Entity, imageNames: a06CardImageNames, entityName: "A06 Card")
    }
    
    /// A07 카드 엔티티 설정
    private func configureA07CardEntity(in rootEntity: Entity) {
        print("🎯 A07 카드 엔티티 설정 시작")
        
        // /Root/RoomScene/A07/A07Card/Cube_007 경로로 찾기
        var targetEntity: Entity?
        
        // RoomScene 찾기
        if let roomScene = rootEntity.findEntity(named: "RoomScene") {
            print("✅ RoomScene 발견")
            
            // A07 찾기
            if let a07 = roomScene.findEntity(named: "A07") {
                print("✅ A07 발견")
                
                // A07Card 찾기
                if let a07Card = a07.findEntity(named: "A07Card") {
                    print("✅ A07Card 발견")
                    
                    // Cube_007 찾기
                    if let cube007 = a07Card.findEntity(named: "Cube_007") {
                        targetEntity = cube007
                        print("✅ Cube_007 발견 (전체 경로: /Root/RoomScene/A07/A07Card/Cube_007)")
                    } else {
                        print("⚠️ Cube_007을 찾을 수 없음")
                        // Cube로 시작하는 다른 엔티티 찾기
                        for child in a07Card.children {
                            if child.name.starts(with: "Cube") {
                                targetEntity = child
                                print("✅ 대체 Cube 엔티티 발견: \(child.name)")
                                break
                            }
                        }
                    }
                } else {
                    print("⚠️ A07Card를 찾을 수 없음")
                }
            } else {
                print("⚠️ A07을 찾을 수 없음")
            }
        } else {
            print("⚠️ RoomScene을 찾을 수 없음")
        }
        
        if let target = targetEntity {
            updateA07CardTexture(target)
        } else {
            print("⚠️ A07 카드 텍스처 대상을 찾을 수 없음")
        }
    }
    
    /// A07 카드 엔티티의 텍스처 업데이트
    private func updateA07CardTexture(_ a07Entity: Entity) {
        print("🎨 A07 카드 텍스처 업데이트 시작")
        updateEntityTexture(a07Entity, imageNames: a07CardImageNames, entityName: "A07 Card")
    }
    
    /// 엔티티의 텍스처 업데이트 (공통 함수)
    private func updateEntityTexture(_ entity: Entity, imageNames: [Language: String], entityName: String) {
        print("  - \(entityName) 엔티티 이름: \(entity.name)")
        print("  - ModelEntity 여부: \(entity is ModelEntity)")
        print("  - 자식 엔티티 수: \(entity.children.count)")
        
        // 자식 엔티티 정보 출력
        for (index, child) in entity.children.enumerated() {
            print("    자식[\(index)]: \(child.name), ModelEntity?: \(child is ModelEntity)")
        }
        
        // 현재 언어에 맞는 이미지 이름 가져오기
        guard let imageName = imageNames[currentLanguage] else {
            print("⚠️ \(entityName): 언어에 해당하는 이미지 이름을 찾을 수 없음")
            return
        }
        
        // UIImage 로드
        guard let uiImage = UIImage(named: imageName) else {
            print("⚠️ \(entityName): 이미지를 로드할 수 없음: \(imageName)")
            return
        }
        
        print("✅ \(entityName): 이미지 로드 성공: \(imageName)")
        
        var textureUpdated = false
        
        // ModelEntity인 경우 Material 변경
        if let modelEntity = entity as? ModelEntity {
            updateModelEntityTexture(modelEntity, with: uiImage, imageName: imageName)
            textureUpdated = true
        }
        
        // 자식들 중에서 ModelEntity 찾기 (재귀적으로)
        func updateChildrenTextures(_ entity: Entity) {
            for child in entity.children {
                if let modelChild = child as? ModelEntity {
                    updateModelEntityTexture(modelChild, with: uiImage, imageName: imageName)
                    textureUpdated = true
                }
                // 재귀적으로 더 깊은 자식들도 확인
                updateChildrenTextures(child)
            }
        }
        
        updateChildrenTextures(entity)
        
        if !textureUpdated {
            print("⚠️ \(entityName): ModelEntity를 찾을 수 없음 - 엔티티 구조를 확인하세요")
        }
    }
    
    /// ModelEntity의 텍스처 업데이트
    private func updateModelEntityTexture(_ modelEntity: ModelEntity, with uiImage: UIImage, imageName: String) {
        do {
            // CGImage로 변환
            guard let cgImage = uiImage.cgImage else {
                print("⚠️ UIImage를 CGImage로 변환 실패")
                return
            }
            
            // TextureResource 생성
            let textureResource = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
            
            // PhysicallyBasedMaterial 생성
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(texture: .init(textureResource))
            
            // 모든 메시의 Material 변경
            if modelEntity.model?.materials.isEmpty == false {
                let meshCount = modelEntity.model?.materials.count ?? 0
                modelEntity.model?.materials = Array(repeating: material, count: meshCount)
                print("✅ Board 텍스처 업데이트 성공: \(imageName) (메시 수: \(meshCount))")
            } else {
                // Materials가 없는 경우 새로 생성
                if let mesh = modelEntity.model?.mesh {
                    modelEntity.model = ModelComponent(mesh: mesh, materials: [material])
                    print("✅ Board 텍스처 설정 성공: \(imageName)")
                }
            }
        } catch {
            print("❌ 텍스처 생성 실패: \(error)")
        }
    }
    
    /// 엔티티 구조 출력 (디버깅용)
    private func printEntityStructure(_ entity: Entity, depth: Int, maxDepth: Int) {
        guard depth < maxDepth else { return }
        
        let indent = String(repeating: "  ", count: depth)
        let modelInfo = (entity as? ModelEntity) != nil ? " [ModelEntity]" : ""
        print("\(indent)- \(entity.name)\(modelInfo)")
        
        for child in entity.children {
            printEntityStructure(child, depth: depth + 1, maxDepth: maxDepth)
        }
    }
    
    /// 언어 변경 (테스트용)
    /// - Parameter language: 변경할 언어
    func setLanguage(_ language: Language) {
        currentLanguage = language
        print("🌐 언어 변경됨: \(language.rawValue)")
    }
}
