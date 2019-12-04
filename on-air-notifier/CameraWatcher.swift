import AVFoundation
import CoreMediaIO
import Foundation

typealias OnAirBlock = (Bool) -> Void

class CameraWatcher {
  public var onAirState: Bool {
    get {
      return currentOnAirState
    }
  }
  
  private var onAirListeners: [OnAirBlock] = []
  private var currentOnAirState: Bool = false
  
  var cameraDeviceProps = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster)
  )
  
  var isRunningProps = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
  )
  
  var watchedCameraIds: [CMIOObjectID] = []
  
  init() {
    addCameraDevicePropertyChangeListener()
  }

  public func setupCameraIsRunnningListeners() {
    for cameraId in watchedCameraIds {
      print("Removing listener for camera \(cameraId)")
      removeCameraIsRunningPropertyChangeListener(cameraId: cameraId)
    }
    
    watchedCameraIds = getCameraIds()
    checkAndHandleCameraState()
    
    for cameraId in watchedCameraIds {
      print("Installing listener for camera \(cameraId)")
      addCameraIsRunningPropertyChangeListener(cameraId: cameraId)
    }
  }
  
  public func addOnAirListener(listener: @escaping OnAirBlock) -> Void {
    onAirListeners.append(listener)
    listener(currentOnAirState)
  }
  
  private func notifyOnAirListeners(onAir: Bool) -> Void {
    for listener in onAirListeners {
      listener(onAir)
    }
  }
  
  private func addCameraDevicePropertyChangeListener() {
    CMIOObjectAddPropertyListenerBlock(
      CMIOObjectID(kCMIOObjectSystemObject), &cameraDeviceProps, DispatchQueue.main, onCameraDevicePropertyChange
    )
  }
  
  private func removeCameraDevicePropertyChangeListener() {
    CMIOObjectRemovePropertyListenerBlock(
      CMIOObjectID(kCMIOObjectSystemObject), &cameraDeviceProps, DispatchQueue.main, onCameraDevicePropertyChange
    )
  }
  
  private func onCameraDevicePropertyChange(_: UInt32?, _: UnsafePointer<CMIOObjectPropertyAddress>?) {
    print("Camera configuration changed (devices added or removed)")
    setupCameraIsRunnningListeners()
  }
  
  private func getCameraIds() -> [CMIOObjectID] {
    var (dataSize, dataUsed) = (UInt32(0), UInt32(0))
    var result = CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &cameraDeviceProps, 0, nil, &dataSize)
    var devices: UnsafeMutableRawPointer?
    
    repeat {
      if devices != nil {
        free(devices)
        devices = nil
      }
      devices = malloc(Int(dataSize))
      result = CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &cameraDeviceProps, 0, nil, dataSize, &dataUsed, devices)
    } while result == OSStatus(kCMIOHardwareBadPropertySizeError)
    
    var cameraIds: [CMIOObjectID] = []
    if let devices = devices {
      for offset in stride(from: 0, to: dataSize, by: MemoryLayout<CMIOObjectID>.size) {
        let current = devices.advanced(by: Int(offset)).assumingMemoryBound(to: CMIOObjectID.self)
        
        let cameraId = current.pointee
        cameraIds.append(cameraId)
      }
    }
    
    free(devices)
    
    return cameraIds
  }
  
  private func checkAndHandleCameraState() {
    var onAir: Bool = false
    let cameraIds = getCameraIds()
    
    for cameraId in cameraIds {
      onAir = onAir || isCameraOnAir(cameraId: cameraId)
    }
    currentOnAirState = onAir
    notifyOnAirListeners(onAir: onAir)
    
    if onAir {
      print("ON AIR!")
    } else {
      print("OFF AIR.")
    }
  }
  
  private func onCameraIsRunningPropertyChange(_: UInt32?, _: UnsafePointer<CMIOObjectPropertyAddress>?) {
    checkAndHandleCameraState()
  }
  
  private func addCameraIsRunningPropertyChangeListener(cameraId: CMIOObjectID) {
    CMIOObjectAddPropertyListenerBlock(cameraId, &isRunningProps, DispatchQueue.main, onCameraIsRunningPropertyChange)
  }
  
  private func removeCameraIsRunningPropertyChangeListener(cameraId: CMIOObjectID) {
    CMIOObjectRemovePropertyListenerBlock(cameraId, &isRunningProps, DispatchQueue.main, onCameraIsRunningPropertyChange)
  }
  
  private func isCameraOnAir(cameraId: CMIOObjectID) -> Bool {
    var (dataSize, dataUsed) = (UInt32(0), UInt32(0))
    
    let result = CMIOObjectGetPropertyDataSize(cameraId, &isRunningProps, 0, nil, &dataSize)
    if result != OSStatus(kCMIOHardwareNoError) {
      return false
    }
    
    if let data = malloc(Int(dataSize)) {
      CMIOObjectGetPropertyData(cameraId, &isRunningProps, 0, nil, dataSize, &dataUsed, data)
      let on = data.assumingMemoryBound(to: UInt8.self)
      return on.pointee != 0
    }
    return false
  }
}
