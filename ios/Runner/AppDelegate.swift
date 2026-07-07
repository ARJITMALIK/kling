import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // ── Custom battery channel ──────────────────────────────────────────────
    // battery_plus throws UNAVAILABLE on some iOS versions because it reads
    // UIDevice.batteryLevel before iOS's internal battery notification loop
    // is ready. We bypass the plugin and read directly here, waiting up to
    // 3 seconds (6 × 500 ms) for a valid (≥ 0) reading.
    let batteryChannel = FlutterMethodChannel(
      name: "com.cling/battery",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    batteryChannel.setMethodCallHandler { (_: FlutterMethodCall, result: @escaping FlutterResult) in
      // Ensure monitoring is on — must be called on main thread
      UIDevice.current.isBatteryMonitoringEnabled = true

      func tryRead(attempt: Int) {
        let level = UIDevice.current.batteryLevel   // -1.0 until monitoring kicks in
        let state = UIDevice.current.batteryState

        if level >= 0 || attempt >= 6 {
          let levelPct = level >= 0 ? Int(level * 100) : -1
          let stateStr: String
          switch state {
          case .charging:   stateStr = "charging"
          case .full:       stateStr = "full"
          case .unplugged:  stateStr = "discharging"
          default:          stateStr = "unknown"
          }
          result(["level": levelPct, "status": stateStr])
        } else {
          // Not ready yet — retry after 500 ms
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tryRead(attempt: attempt + 1)
          }
        }
      }

      tryRead(attempt: 0)
    }
    // ── End custom battery channel ─────────────────────────────────────────
  }
}
