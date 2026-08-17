import Flutter
import UIKit
import CFNetwork
import TDMobRisk

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let faceLivenessBridge = FaceLivenessBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "FundNexusCaptureProxy"
    ) else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "fund_nexus/capture_proxy",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "getSystemProxy" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue()
          as? [String: Any],
        (settings[kCFNetworkProxiesHTTPEnable as String] as? NSNumber)?.boolValue == true,
        let host = settings[kCFNetworkProxiesHTTPProxy as String] as? String,
        let port = (settings[kCFNetworkProxiesHTTPPort as String] as? NSNumber)?.intValue,
        !host.isEmpty,
        port > 0
      else {
        result(nil as Any?)
        return
      }
      result(["host": host, "port": port])
    }

    let faceLivenessChannel = FlutterMethodChannel(
      name: "fund_nexus/face_liveness",
      binaryMessenger: registrar.messenger()
    )
    faceLivenessChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "start" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.faceLivenessBridge.start(call.arguments, result: result)
    }
  }
}

private final class FaceLivenessBridge {
  private let partnerCode = "boqin_ph"
  private let partnerKey = "1dc25522f2adc77f5347816c0f7fa31b"
  private let country = "sg"
  private lazy var riskManager = TDMobRiskManager.sharedManager()
  private var configured = false

  func start(_ arguments: Any?, result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        result([
          "success": false,
          "code": -1,
          "message": "Face verification is unavailable.",
          "image": "",
          "liveness_id": ""
        ])
        return
      }
      self.startOnMain(arguments, result: result)
    }
  }

  private func configureIfNeeded() {
    guard !configured else { return }
    configured = true
    NSLog("[FaceLiveness] initializing TrustDecision SDK")
    var options: [String: Any] = [
      "partner": partnerCode,
      "appKey": partnerKey,
      "country": country,
      "language": "en",
      "showReadyPage": false,
      "runningTasks": false,
      "readPhonoe": false,
      "installPackageList": false,
      "playAudio": true
    ]
#if DEBUG
    options["allowed"] = true
#endif
    riskManager?.pointee.initWithOptions(options)
    NSLog("[FaceLiveness] TrustDecision SDK initialized")
  }

  private func startOnMain(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let license = arguments as? String,
      !license.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      NSLog("[FaceLiveness] rejected start request: empty license")
      result(failure(message: "Face verification license is missing."))
      return
    }
    configureIfNeeded()
    guard let viewController = topViewController() else {
      NSLog("[FaceLiveness] cannot find a presentation view controller")
      result(failure(message: "Unable to present face verification."))
      return
    }
    NSLog("[FaceLiveness] presenting TrustDecision liveness")
    riskManager?.pointee.showLivenessWithShowStyle(
      viewController,
      license,
      TDLivenessShowStylePresent,
      { payload in
        NSLog("[FaceLiveness] liveness succeeded")
        result(self.wrap(success: true, payload: payload))
      },
      { payload in
        NSLog("[FaceLiveness] liveness failed")
        result(self.wrap(success: false, payload: payload))
      }
    )
  }

  private func wrap(
    success: Bool,
    payload: [AnyHashable: Any]?
  ) -> [String: Any] {
    let raw = (payload as? [String: Any]) ?? [:]
    let code = (raw["code"] as? NSNumber)?.intValue ?? (success ? 0 : -1)
    return [
      "success": success,
      "code": code,
      "message": raw["message"] as? String ?? "",
      "image": raw["image"] as? String ?? "",
      "liveness_id": raw["liveness_id"] as? String ?? ""
    ]
  }

  private func failure(message: String) -> [String: Any] {
    return [
      "success": false,
      "code": -1,
      "message": message,
      "image": "",
      "liveness_id": ""
    ]
  }

  private func topViewController(
    from viewController: UIViewController? = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: \.isKeyWindow)?
      .rootViewController
  ) -> UIViewController? {
    if let navigationController = viewController as? UINavigationController {
      return topViewController(from: navigationController.visibleViewController)
    }
    if let tabBarController = viewController as? UITabBarController {
      return topViewController(from: tabBarController.selectedViewController)
    }
    if let presentedViewController = viewController?.presentedViewController {
      return topViewController(from: presentedViewController)
    }
    return viewController
  }
}
