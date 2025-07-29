//
//  CameraSensitivityManager.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import Foundation
import simd

@MainActor
final class CameraSensitivityManager {
  static let shared = CameraSensitivityManager()
  private init() {}
  
  // MARK: - Sensitivity Configuration
  
  private let sensitivityMultiplier: Float = 5.0
  private let pitchReductionFactor: Float = 0.5
  
  // MARK: - Public Methods
  
  /// 감도 증폭 함수
  func applySensitivityAmplification(transform: simd_float4x4) -> simd_float4x4 {
    // 회전 행렬 추출
    let rotationMatrix = simd_float3x3(
      SIMD3<Float>(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z),
      SIMD3<Float>(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z),
      SIMD3<Float>(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
    )
    
    // Y축 회전각 (좌우 회전) 추출
    let yaw = atan2(rotationMatrix.columns.0.z, rotationMatrix.columns.2.z)
    
    // X축 회전각 (상하 회전) 추출  
    let pitch = atan2(-rotationMatrix.columns.1.z, sqrt(pow(rotationMatrix.columns.1.x, 2) + pow(rotationMatrix.columns.1.y, 2)))
    
    // 감도 증폭
    let amplifiedYaw = yaw * sensitivityMultiplier
    let amplifiedPitch = pitch * sensitivityMultiplier * pitchReductionFactor  // 상하는 절반 증폭
    
    // 증폭된 회전 행렬 생성
    let cosYaw = cos(amplifiedYaw)
    let sinYaw = sin(amplifiedYaw)
    let cosPitch = cos(amplifiedPitch)
    let sinPitch = sin(amplifiedPitch)
    
    let amplifiedRotation = simd_float3x3(
      SIMD3<Float>(cosYaw, 0, sinYaw),
      SIMD3<Float>(sinYaw * sinPitch, cosPitch, -cosYaw * sinPitch),
      SIMD3<Float>(-sinYaw * cosPitch, sinPitch, cosYaw * cosPitch)
    )
    
    // 위치는 그대로 유지
    let position = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    
    return simd_float4x4(
      SIMD4<Float>(amplifiedRotation.columns.0, 0),
      SIMD4<Float>(amplifiedRotation.columns.1, 0), 
      SIMD4<Float>(amplifiedRotation.columns.2, 0),
      SIMD4<Float>(position, 1)
    )
  }
  
  /// 시뮬레이터용 회전 행렬 생성
  func createSimulatorRotationMatrix(angle: Float, amplificationFactor: Float = 0.1) -> simd_float4x4 {
    let amplifiedAngle = angle * amplificationFactor
    
    let cosAngle = cos(amplifiedAngle)
    let sinAngle = sin(amplifiedAngle)
    
    return simd_float4x4(
      SIMD4<Float>(cosAngle, 0, sinAngle, 0),
      SIMD4<Float>(0, 1, 0, 0),
      SIMD4<Float>(-sinAngle, 0, cosAngle, 0),
      SIMD4<Float>(0, 0, 0, 1)
    )
  }
  
  /// 시뮬레이터용 카메라 방향 벡터 계산
  func calculateSimulatorCameraVectors(angle: Float, amplificationFactor: Float = 0.1) -> (forward: SIMD3<Float>, right: SIMD3<Float>) {
    let amplifiedAngle = angle * amplificationFactor
    
    let forward = SIMD3<Float>(-sin(amplifiedAngle), 0, cos(amplifiedAngle))
    let right = SIMD3<Float>(cos(amplifiedAngle), 0, sin(amplifiedAngle))
    
    return (forward: forward, right: right)
  }
} 