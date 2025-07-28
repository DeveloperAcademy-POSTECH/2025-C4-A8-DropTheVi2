//
//  AttachViewModel.swift
//  EscapeVision
//
//  Created by 조재훈 on 7/27/25.
//

import Foundation
import RealityKit
import SwiftUI

@Observable
final class AttachViewModel {
  static let shared = AttachViewModel()
  
  private init() {}
  
  private let positionManager = PositionManager.shared
  
  var showPasswordModal: Bool = false
  var showMonitorModal: Bool = false
  var showFileModal: Bool = false
  var showNoteModal: Bool = false
  
  private let keypadPosition: SIMD3<Float> = SIMD3(-0.83808, 1.37728, 1.10787) // Y축 +0.3
  private let notePosition: SIMD3<Float> = SIMD3(-0.83808, 1.37728, 1.10787)
  private let machinePosition = SIMD3<Float>(1.69722, 1.86142, -0.54857) // 수면가스 기계 좌표
  private let controlMonitorPosition = SIMD3<Float>(1.7007, 0.94853, -0.58316) // 조작 모니터 화면 위치 좌표 y + 0.5
  private let patientMonitorPosition = SIMD3<Float>(1.62414, 1.21879, 0.05951) // 환자 모니터 화면 위치 좌표 y + 0.4
  private let particlePosition = SIMD3<Float>(0.79441, 0.57728, -0.60016) // 파티클 좌표
  private let filePosition = SIMD3<Float>(-1.58947, 1.37728, 1.10787)
  
  func attachEntity(
    _ entity: ViewAttachmentEntity,
    type: AttachmentType,
    content: RealityViewContent
  ) {
    positionManager.applyConfiguration(
      to: entity,
      type: type,
      content: content
    )
  }
}
