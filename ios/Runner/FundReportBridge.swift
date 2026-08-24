import AdSupport
import AppTrackingTransparency
import CoreLocation
import Flutter
import UIKit
import UserNotifications

final class FundReportBridge: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  static let shared = FundReportBridge()

  private var eventSink: FlutterEventSink?
  private var pushToken = ""
  private var pendingNotificationRoutes: [String] = []
  private var locationManager: CLLocationManager?
  private var locationResult: FlutterResult?
  private var waitingLocationPermission = false

  func register(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "fund_nexus/report_bridge", binaryMessenger: binaryMessenger)
    let events = FlutterEventChannel(name: "fund_nexus/report_events", binaryMessenger: binaryMessenger)
    events.setStreamHandler(self)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "getLocation": self.getLocation(result)
      case "getDeviceSnapshot": result(self.deviceSnapshot())
      case "getPushToken": result(self.pushToken)
      case "getTrackingStatus": result(self.trackingStatus())
      case "requestNotificationPermission": self.requestNotificationPermission(result)
      case "requestTrackingPermission": self.requestTrackingPermission(result)
      case "requestLocationPermission": self.requestLocationPermission(result)
      case "registerForRemoteNotifications":
        DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications(); result(nil) }
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    if !pushToken.isEmpty { events(["type": "push_token", "token": pushToken]) }
    while !pendingNotificationRoutes.isEmpty {
      let route = pendingNotificationRoutes.removeFirst()
      events(["type": "push_route", "url": route])
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? { eventSink = nil; return nil }

  func updatePushToken(_ token: String) {
    pushToken = token
    if !token.isEmpty { eventSink?(["type": "push_token", "token": token]) }
  }

  @discardableResult
  func acceptNotificationPayload(_ userInfo: [AnyHashable: Any]) -> Bool {
    NSLog("[FundReportBridge] acceptNotificationPayload called")
    NSLog("[FundReportBridge] userInfo: \(userInfo)")
    guard let route = notificationRoute(from: userInfo) else {
      NSLog("[FundReportBridge] Failed to extract route from notification payload")
      return false
    }
    NSLog("[FundReportBridge] Extracted route: \(route)")
    guard let eventSink else {
      NSLog("[FundReportBridge] EventSink not available, queueing route")
      pendingNotificationRoutes.append(route)
      return true
    }
    NSLog("[FundReportBridge] Sending push_route event to Flutter")
    eventSink(["type": "push_route", "url": route])
    NSLog("[FundReportBridge] Event sent successfully")
    return true
  }

  private func notificationRoute(from userInfo: [AnyHashable: Any]) -> String? {
    if let route = normalizedNotificationRoute(userInfo["url"]) {
      return route
    }
    if let params = userInfo["params"] as? [AnyHashable: Any] {
      return normalizedNotificationRoute(params["url"])
    }
    guard
      let paramsText = userInfo["params"] as? String,
      let paramsData = paramsText.data(using: .utf8),
      let decoded = try? JSONSerialization.jsonObject(with: paramsData),
      let params = decoded as? [String: Any]
    else {
      return nil
    }
    return normalizedNotificationRoute(params["url"])
  }

  private func normalizedNotificationRoute(_ value: Any?) -> String? {
    guard let value = value as? String else {
      return nil
    }
    let route = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return route.isEmpty ? nil : route
  }

  private func getLocation(_ result: @escaping FlutterResult) {
    guard CLLocationManager.locationServicesEnabled() else { result(["permissionStatus": "service_disabled"]); return }
    let manager = CLLocationManager()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    locationManager = manager
    locationResult = result
    waitingLocationPermission = false
    let status = manager.authorizationStatus
    guard status == .authorizedAlways || status == .authorizedWhenInUse else {
      finishLocation(["permissionStatus": statusText(status)])
      return
    }
    manager.requestLocation()
  }

  private func requestLocationPermission(_ result: @escaping FlutterResult) {
    let manager = CLLocationManager()
    manager.delegate = self
    let status = manager.authorizationStatus
    guard status == .notDetermined else { result(statusText(status)); return }
    locationManager = manager
    locationResult = result
    waitingLocationPermission = true
    manager.requestWhenInUseAuthorization()
  }

  private func requestTrackingPermission(_ result: @escaping FlutterResult) {
    guard #available(iOS 14, *) else { result(nil); return }
    guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { result(nil); return }
    ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
      DispatchQueue.main.async {
        self?.eventSink?(["type": "tracking_status_changed", "status": self?.trackingStatus() ?? ""])
        result(nil)
      }
    }
  }

  private func requestNotificationPermission(_ result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { _, _ in
      DispatchQueue.main.async { result(nil) }
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard let result = locationResult, manager === locationManager else { return }
    let status = manager.authorizationStatus
    guard status != .notDetermined else { return }
    if waitingLocationPermission {
      waitingLocationPermission = false
      result(statusText(status)); locationResult = nil; locationManager = nil
    } else if status == .authorizedAlways || status == .authorizedWhenInUse {
      manager.requestLocation()
    } else {
      finishLocation(["permissionStatus": statusText(status)])
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { finishLocation(["permissionStatus": statusText(manager.authorizationStatus)]); return }
    let geocoder = CLGeocoder()
    geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
      guard let self else { return }
      let placemark = placemarks?.first
      self.finishLocation([
        "province": placemark?.administrativeArea ?? "", "locality": placemark?.subAdministrativeArea ?? "",
        "fullAddress": placemark?.name ?? "", "countryCode": placemark?.isoCountryCode ?? "", "country": placemark?.country ?? "",
        "street": placemark?.thoroughfare ?? "", "latitude": "\(location.coordinate.latitude)", "longitude": "\(location.coordinate.longitude)",
        "city": placemark?.locality ?? "", "permissionStatus": self.statusText(manager.authorizationStatus)
      ])
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { finishLocation(["permissionStatus": statusText(manager.authorizationStatus)]) }

  private func finishLocation(_ payload: [String: Any]) {
    let result = locationResult
    locationResult = nil
    waitingLocationPermission = false
    locationManager?.stopUpdatingLocation()
    locationManager = nil
    result?(payload)
  }

  private func deviceSnapshot() -> [String: Any] {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true
    let info = Bundle.main.infoDictionary
    let idfv = device.identifierForVendor?.uuidString ?? ""
    let screen = UIScreen.main.bounds
    return [
      "idfv": idfv, "idfa": currentIdfa(), "riskDeviceId": "", "batteryLevel": max(0, Int(device.batteryLevel * 100)),
      "isCharging": device.batteryState == .charging || device.batteryState == .full ? 1 : 0, "elapsedMillis": 0, "uptimeMillis": "\(Int(ProcessInfo.processInfo.systemUptime * 1000))",
      "isUsingProxy": 0, "isUsingVpn": 0, "isJailbroken": 0, "isEmulator": 0, "language": Locale.preferredLanguages.first ?? "",
      "carrier": "", "networkType": "", "timeZoneName": TimeZone.current.identifier, "cpuCoreCount": ProcessInfo.processInfo.processorCount,
      "brand": "Apple", "deviceName": device.name, "model": device.model, "systemVersion": device.systemVersion, "packageName": info?["CFBundleIdentifier"] as? String ?? "",
      "screenHeight": Int(screen.height), "screenWidth": Int(screen.width), "screenSize": "", "innerIp": "", "currentWifiName": "", "currentWifiBssid": "", "wifiCount": 0,
      "availableStorage": "0", "totalStorage": "0", "totalMemory": "\(ProcessInfo.processInfo.physicalMemory)", "availableMemory": "0"
    ]
  }

  private func currentIdfa() -> String {
    if #available(iOS 14, *) { guard ATTrackingManager.trackingAuthorizationStatus == .authorized else { return "" } }
    return ASIdentifierManager.shared().advertisingIdentifier.uuidString
  }

  private func trackingStatus() -> String {
    if #available(iOS 14, *) {
      switch ATTrackingManager.trackingAuthorizationStatus { case .authorized: return "authorized"; case .denied: return "denied"; case .restricted: return "restricted"; default: return "not_determined" }
    }
    return "authorized"
  }

  private func statusText(_ status: CLAuthorizationStatus) -> String {
    switch status { case .authorizedAlways: return "authorized_always"; case .authorizedWhenInUse: return "authorized_when_in_use"; case .denied: return "denied"; case .restricted: return "restricted"; default: return "not_determined" }
  }
}
