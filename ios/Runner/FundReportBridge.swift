import AdSupport
import AppTrackingTransparency
import CFNetwork
import CoreTelephony
import CoreLocation
import Darwin
import Flutter
import NetworkExtension
import Security
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork
import UIKit
import UserNotifications

private struct FundWifiSnapshot {
  let name: String
  let bssid: String
  let count: Int

  static let empty = FundWifiSnapshot(name: "", bssid: "", count: 0)
}

private struct FundInterfaceRecord {
  let name: String
  let family: Int32
  let address: String
}

final class FundReportBridge: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  static let shared = FundReportBridge()

  private let telephony = CTTelephonyNetworkInfo()
  private var eventSink: FlutterEventSink?
  private var pushToken = ""
  private var pendingNotificationRoutes: [String] = []
  private var locationManager: CLLocationManager?
  private var locationResult: FlutterResult?
  private var waitingLocationPermission = false
  private var isRegistered = false

  func register(binaryMessenger: FlutterBinaryMessenger) {
    guard !isRegistered else { return }
    isRegistered = true
    let channel = FlutterMethodChannel(name: "fund_nexus/report_bridge", binaryMessenger: binaryMessenger)
    let events = FlutterEventChannel(name: "fund_nexus/report_events", binaryMessenger: binaryMessenger)
    events.setStreamHandler(self)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "getLocation": self.getLocation(result)
      case "getDeviceSnapshot": self.getDeviceSnapshot(result)
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

  private func getDeviceSnapshot(_ result: @escaping FlutterResult) {
    collectWifi { [weak self] wifi in
      guard let self else { return }
      result(self.deviceSnapshot(wifi: wifi))
    }
  }

  private func deviceSnapshot(wifi: FundWifiSnapshot) -> [String: Any] {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true
    let batteryLevel =
      device.batteryLevel < 0 ? 0 : Int(device.batteryLevel * 100)
    let batteryState = device.batteryState
    device.isBatteryMonitoringEnabled = false
    let info = Bundle.main.infoDictionary
    let idfv = stableVendorIdentifier()
    let screen = UIScreen.main.bounds
    let uptime = Int(ProcessInfo.processInfo.systemUptime * 1000)
    let fileAttributes = try? FileManager.default.attributesOfFileSystem(
      forPath: NSHomeDirectory()
    )
    let totalStorage =
      (fileAttributes?[.systemSize] as? NSNumber)?.stringValue ?? "0"
    let availableStorage =
      (fileAttributes?[.systemFreeSize] as? NSNumber)?.stringValue ?? "0"
    let interfaces = activeInterfaces()
    return [
      "idfv": idfv,
      "idfa": currentIdfa(),
      "riskDeviceId": idfv,
      "batteryLevel": batteryLevel,
      "isCharging": batteryState == .charging || batteryState == .full ? 1 : 0,
      "elapsedMillis": uptime,
      "uptimeMillis": "\(uptime)",
      "isUsingProxy": isUsingProxy() ? 1 : 0,
      "isUsingVpn": isUsingVpn() ? 1 : 0,
      "isJailbroken": isJailbroken() ? 1 : 0,
      "isEmulator": isSimulator() ? 1 : 0,
      "language": Locale.current.languageCode ?? "",
      "carrier": currentCarrierName(),
      "networkType": currentNetworkType(),
      "timeZoneName": gmtTimeZone(),
      "cpuCoreCount": ProcessInfo.processInfo.processorCount,
      "brand": "iPhone",
      "deviceName": device.name,
      "model": deviceModelName(),
      "systemVersion": device.systemVersion,
      "packageName": info?["CFBundleIdentifier"] as? String ?? "",
      "screenHeight": Int(screen.height),
      "screenWidth": Int(screen.width),
      "screenSize": "",
      "innerIp": preferredInnerIp(from: interfaces),
      "currentWifiName": wifi.name,
      "currentWifiBssid": wifi.bssid,
      "wifiCount": wifi.count,
      "availableStorage": availableStorage,
      "totalStorage": totalStorage,
      "totalMemory": "\(ProcessInfo.processInfo.physicalMemory)",
      "availableMemory": "\(availableMemoryBytes())",
    ]
  }

  private func collectWifi(
    completion: @escaping (FundWifiSnapshot) -> Void
  ) {
    if #available(iOS 26.0, *) {
      NEHotspotNetwork.fetchCurrent { network in
        let snapshot = network.map {
          FundWifiSnapshot(name: $0.ssid, bssid: $0.bssid, count: 1)
        } ?? .empty
        DispatchQueue.main.async { completion(snapshot) }
      }
      return
    }

    DispatchQueue.global(qos: .utility).async {
      let networks =
        (CNCopySupportedInterfaces() as? [String] ?? []).compactMap {
          interface -> FundWifiSnapshot? in
          guard
            let info = CNCopyCurrentNetworkInfo(interface as CFString)
              as? [String: Any]
          else {
            return nil
          }
          return FundWifiSnapshot(
            name: info[kCNNetworkInfoKeySSID as String] as? String ?? "",
            bssid: info[kCNNetworkInfoKeyBSSID as String] as? String ?? "",
            count: 1
          )
        }
      let first = networks.first ?? .empty
      let snapshot = FundWifiSnapshot(
        name: first.name,
        bssid: first.bssid,
        count: networks.count
      )
      DispatchQueue.main.async { completion(snapshot) }
    }
  }

  private func currentCarrierName() -> String {
    if let providers = telephony.serviceSubscriberCellularProviders {
      for key in providers.keys.sorted() {
        let name = providers[key]?.carrierName?.trimmingCharacters(
          in: .whitespacesAndNewlines
        ) ?? ""
        if !name.isEmpty { return name }
      }
    }
    return telephony.subscriberCellularProvider?.carrierName ?? ""
  }

  private func currentNetworkType() -> String {
    guard let flags = reachabilityFlags(), flags.contains(.reachable) else {
      return "OTHER"
    }
    guard flags.contains(.isWWAN) else { return "WIFI" }
    return cellularGeneration()
  }

  private func reachabilityFlags() -> SCNetworkReachabilityFlags? {
    var address = sockaddr_in()
    address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    address.sin_family = sa_family_t(AF_INET)
    let reachability = withUnsafePointer(to: &address) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        SCNetworkReachabilityCreateWithAddress(nil, $0)
      }
    }
    guard let reachability else { return nil }
    var flags = SCNetworkReachabilityFlags()
    return SCNetworkReachabilityGetFlags(reachability, &flags) ? flags : nil
  }

  private func cellularGeneration() -> String {
    let technologies = telephony.serviceCurrentRadioAccessTechnology ?? [:]
    let technology = technologies.keys.sorted().compactMap {
      technologies[$0]
    }.first ?? telephony.currentRadioAccessTechnology

    switch technology {
    case CTRadioAccessTechnologyGPRS,
      CTRadioAccessTechnologyEdge,
      CTRadioAccessTechnologyCDMA1x:
      return "2G"
    case CTRadioAccessTechnologyWCDMA,
      CTRadioAccessTechnologyHSDPA,
      CTRadioAccessTechnologyHSUPA,
      CTRadioAccessTechnologyCDMAEVDORev0,
      CTRadioAccessTechnologyCDMAEVDORevA,
      CTRadioAccessTechnologyCDMAEVDORevB,
      CTRadioAccessTechnologyeHRPD:
      return "3G"
    case CTRadioAccessTechnologyLTE:
      return "4G"
    case CTRadioAccessTechnologyNRNSA, CTRadioAccessTechnologyNR:
      return "5G"
    default:
      return "OTHER"
    }
  }

  private func activeInterfaces() -> [FundInterfaceRecord] {
    var pointer: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&pointer) == 0, let first = pointer else { return [] }
    defer { freeifaddrs(pointer) }

    var records: [FundInterfaceRecord] = []
    for item in sequence(first: first, next: { $0.pointee.ifa_next }) {
      let interface = item.pointee
      let flags = Int32(interface.ifa_flags)
      guard
        flags & IFF_UP != 0,
        flags & IFF_RUNNING != 0,
        flags & IFF_LOOPBACK == 0,
        let socketAddress = interface.ifa_addr
      else {
        continue
      }
      let family = Int32(socketAddress.pointee.sa_family)
      guard family == AF_INET || family == AF_INET6 else { continue }

      var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
      let length = family == AF_INET
        ? socklen_t(MemoryLayout<sockaddr_in>.size)
        : socklen_t(MemoryLayout<sockaddr_in6>.size)
      guard
        getnameinfo(
          socketAddress,
          length,
          &host,
          socklen_t(host.count),
          nil,
          0,
          NI_NUMERICHOST
        ) == 0
      else {
        continue
      }
      let value = String(cString: host)
      if value.isEmpty || value == "127.0.0.1" || value == "::1" {
        continue
      }
      records.append(
        FundInterfaceRecord(
          name: String(cString: interface.ifa_name),
          family: family,
          address: value
        )
      )
    }
    return records
  }

  private func isUsingProxy() -> Bool {
    guard
      let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue()
        as? [String: Any]
    else {
      return false
    }
    let enabled =
      (settings[kCFNetworkProxiesHTTPEnable as String] as? NSNumber)?.boolValue
      ?? false
    let host = settings[kCFNetworkProxiesHTTPProxy as String] as? String ?? ""
    let port =
      (settings[kCFNetworkProxiesHTTPPort as String] as? NSNumber)?.intValue
      ?? 0
    return enabled && !host.isEmpty && port > 0
  }

  private func isUsingVpn() -> Bool {
    guard
      let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue()
        as? [String: Any],
      let scoped = settings["__SCOPED__"] as? [String: Any]
    else {
      return false
    }
    let markers = ["tap", "tun", "ppp", "ipsec", "utun"]
    return scoped.keys.contains { key in
      let name = key.lowercased()
      return markers.contains { name.contains($0) }
    }
  }

  private func gmtTimeZone() -> String {
    let offset = TimeZone.current.secondsFromGMT()
    guard offset != 0 else { return "GMT" }

    let sign = offset >= 0 ? "+" : "-"
    let totalMinutes = abs(offset) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    guard minutes != 0 else { return "GMT\(sign)\(hours)" }
    return String(format: "GMT%@%d:%02d", sign, hours, minutes)
  }

  private func preferredInnerIp(from interfaces: [FundInterfaceRecord]) -> String {
    let priorities: [(String, Int32)] = [
      ("en0", AF_INET),
      ("pdp_ip0", AF_INET),
      ("en0", AF_INET6),
      ("pdp_ip0", AF_INET6),
    ]
    for (name, family) in priorities {
      if let record = interfaces.first(where: {
        $0.name == name && $0.family == family
      }) {
        return record.address
      }
    }
    return ""
  }

  private func availableMemoryBytes() -> UInt64 {
    var pageSize: vm_size_t = 0
    guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else {
      return 0
    }
    var statistics = vm_statistics64()
    var count = mach_msg_type_number_t(
      MemoryLayout<vm_statistics64_data_t>.size
        / MemoryLayout<integer_t>.size
    )
    let status = withUnsafeMutablePointer(to: &statistics) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
      }
    }
    guard status == KERN_SUCCESS else { return 0 }
    return UInt64(statistics.free_count + statistics.inactive_count)
      * UInt64(pageSize)
  }

  private func deviceModelName() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let identifier = withUnsafePointer(to: &systemInfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) {
        String(validatingUTF8: $0) ?? ""
      }
    }
    return identifier.isEmpty ? UIDevice.current.model : identifier
  }

  private func isSimulator() -> Bool {
    #if targetEnvironment(simulator)
      return true
    #else
      return false
    #endif
  }

  private func isJailbroken() -> Bool {
    #if targetEnvironment(simulator)
      return false
    #else
      let paths = [
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/private/var/lib/apt",
      ]
      if paths.contains(where: FileManager.default.fileExists(atPath:)) {
        return true
      }
      if getenv("DYLD_INSERT_LIBRARIES") != nil { return true }

      let probe = "/private/fund-nexus-device-\(UUID().uuidString)"
      do {
        try "probe".write(toFile: probe, atomically: true, encoding: .utf8)
        try? FileManager.default.removeItem(atPath: probe)
        return true
      } catch {
        return false
      }
    #endif
  }

  private func currentIdfa() -> String {
    if #available(iOS 14, *) { guard ATTrackingManager.trackingAuthorizationStatus == .authorized else { return "" } }
    let identifier = ASIdentifierManager.shared().advertisingIdentifier.uuidString
    return identifier == "00000000-0000-0000-0000-000000000000" ? "" : identifier
  }

  private func stableVendorIdentifier() -> String {
    let service = "fund_nexus.report_bridge"
    let account = "stable_idfv"
    if let stored = keychainValue(service: service, account: account),
       !stored.isEmpty {
      return stored
    }

    let identifier = UIDevice.current.identifierForVendor?.uuidString ?? ""
    if !identifier.isEmpty {
      saveKeychainValue(identifier, service: service, account: account)
    }
    return identifier
  }

  private func keychainValue(service: String, account: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  private func saveKeychainValue(
    _ value: String,
    service: String,
    account: String
  ) {
    guard let data = value.data(using: .utf8) else { return }
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    let attributes: [String: Any] = [kSecValueData as String: data]
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      var item = query
      item[kSecValueData as String] = data
      SecItemAdd(item as CFDictionary, nil)
    }
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
