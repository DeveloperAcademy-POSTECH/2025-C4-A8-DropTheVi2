//
//  SwitchComponents.swift
//  EscapeVision
//
//  Created by Assistant on 1/31/25.
//

import Foundation
import RealityKit

// MARK: - Switch Component
/// 스위치 정보를 관리하는 컴포넌트
public struct SwitchComponent: Component {
  public let switchIndex: Int
  public let handleCount: Int
  
  public init(switchIndex: Int, handleCount: Int = 1) {
    self.switchIndex = switchIndex
    self.handleCount = handleCount
  }
}

// MARK: - Handle Component
/// 핸들 상태를 관리하는 컴포넌트
public struct HandleComponent: Component {
  public let switchIndex: Int
  public var isAttached: Bool
  public var isBeingDragged: Bool
  
  public init(switchIndex: Int, isAttached: Bool = false, isBeingDragged: Bool = false) {
    self.switchIndex = switchIndex
    self.isAttached = isAttached
    self.isBeingDragged = isBeingDragged
  }
}
