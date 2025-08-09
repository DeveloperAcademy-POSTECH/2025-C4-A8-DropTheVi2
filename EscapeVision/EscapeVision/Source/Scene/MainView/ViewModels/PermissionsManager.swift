//
//  PermissionsManager.swift
//  EscapeVision
//
//  Created by AI Assistant.
//

import SwiftUI
import ARKit
import AVFoundation
import CoreMotion

@MainActor
final class PermissionsManager: NSObject, ObservableObject {
  static let shared = PermissionsManager()
  
  @Published var permissionsGranted = false
  @Published var permissionStatuses: [String: String] = [:]
  
  /// 필요한 권한들을 요청합니다
  func requestAllPermissions() async {
    print("🔐 [권한 요청] 필요한 권한 요청 시작")
    
    // 1. 카메라 권한 요청
    await requestCameraPermission()
    
    // 2. 모션 권한 요청 (iOS 17+, visionOS)
    await requestMotionPermission()
    
    // 3. ARKit 권한 요청
    await requestARKitPermissions()
    
    // 권한 상태 업데이트
    await updatePermissionStatuses()
    
    print("🔐 [권한 요청] 필요한 권한 요청 완료")
    print("📊 [권한 상태] \(permissionStatuses)")
  }
  
  // MARK: - Individual Permission Requests
  
  private func requestCameraPermission() async {
    print("📹 [카메라 권한] 요청 중...")
    
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    
    switch status {
    case .notDetermined:
      // visionOS에서는 실제 캡처 세션을 생성해야 권한 팝업이 나타날 수 있음
      let granted = await AVCaptureDevice.requestAccess(for: .video)
      if granted {
        print("📹 [카메라 권한] 결과: 허용")
        // 실제 사용을 시도하여 확실히 권한 팝업 표시
        await tryUsingCamera()
      } else {
        print("📹 [카메라 권한] 결과: 거부")
      }
    case .authorized:
      print("📹 [카메라 권한] 이미 허용됨")
    case .denied, .restricted:
      print("📹 [카메라 권한] 거부됨 또는 제한됨")
    @unknown default:
      print("📹 [카메라 권한] 알 수 없는 상태")
    }
  }
  
  private func tryUsingCamera() async {
    do {
      let captureSession = AVCaptureSession()
      guard let camera = AVCaptureDevice.default(for: .video) else {
        print("📹 [카메라] 기본 카메라 기기를 찾을 수 없음")
        return
      }
      
      let input = try AVCaptureDeviceInput(device: camera)
      if captureSession.canAddInput(input) {
        captureSession.addInput(input)
        print("📹 [카메라] 임시 캡처 세션 생성 성공")
        
        // 잠시 후 세션 정리
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          captureSession.stopRunning()
        }
      }
    } catch {
      print("📹 [카메라] 캡처 세션 생성 실패: \(error)")
    }
  }
  

  
  private func requestMotionPermission() async {
    print("🏃 [모션 권한] 요청 중...")
    
    // CMMotionManager를 사용하여 모션 데이터 접근 시도
    // visionOS에서는 자동으로 권한 요청됨
    let motionManager = CMMotionManager()
    
    if motionManager.isDeviceMotionAvailable {
      motionManager.startDeviceMotionUpdates()
      
      // 잠시 후 정지
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        motionManager.stopDeviceMotionUpdates()
        print("🏃 [모션 권한] 요청 완료")
      }
    } else {
      print("🏃 [모션 권한] 기기에서 지원되지 않음")
    }
  }
  
  private func requestARKitPermissions() async {
    print("🥽 [ARKit 권한] 요청 중...")
    
    let session = ARKitSession()
    
    do {
      // 모든 ARKit 관련 권한 요청
      let authorizationTypes: [ARKitSession.AuthorizationType] = [
        .worldSensing,
        // .handTracking, // 필요시 추가
        // .planeDetection, // 필요시 추가
      ]
      
      let authorizationResult = await session.requestAuthorization(for: authorizationTypes)
      
      for (authorizationType, authorizationStatus) in authorizationResult {
        print("🥽 [ARKit 권한] \(authorizationType): \(authorizationStatus)")
        
        switch authorizationStatus {
        case .allowed:
          print("✅ [ARKit] \(authorizationType) 허용됨")
        case .denied:
          print("❌ [ARKit] \(authorizationType) 거부됨")
        @unknown default:
          print("❓ [ARKit] \(authorizationType) 알 수 없는 상태: \(authorizationStatus)")
        }
      }
      
    } catch {
      print("❌ [ARKit 권한] 요청 실패: \(error)")
    }
  }
  
  // MARK: - Status Updates
  
  private func updatePermissionStatuses() async {
    var statuses: [String: String] = [:]
    
    // 카메라
    let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    statuses["카메라"] = authorizationStatusString(cameraStatus)
    
    permissionStatuses = statuses
    
    // 필요한 권한이 허용되었는지 확인
    let allGranted = statuses.values.allSatisfy { $0.contains("허용") }
    permissionsGranted = allGranted
  }
  
  // MARK: - Helper Methods
  
  private func authorizationStatusString(_ status: AVAuthorizationStatus) -> String {
    switch status {
    case .authorized: return "✅ 허용됨"
    case .denied: return "❌ 거부됨"
    case .restricted: return "⚠️ 제한됨"
    case .notDetermined: return "❓ 미결정"
    @unknown default: return "❓ 알 수 없음"
    }
  }
} 