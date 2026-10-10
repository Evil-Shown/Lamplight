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
    registerHaptics(with: engineBridge.pluginRegistry)
  }

  /// Taptic Engine bridge: `notification` (success / warning / error),
  /// `impact` (light / medium / heavy / soft / rigid) and `selection`.
  /// Generators are kept alive and re-prepared so the tap fires with no lag.
  private func registerHaptics(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "LamplightHaptics") else { return }
    let channel = FlutterMethodChannel(
      name: "lamplight/haptics",
      binaryMessenger: registrar.messenger()
    )
    let notification = UINotificationFeedbackGenerator()
    let selection = UISelectionFeedbackGenerator()
    let impacts: [String: UIImpactFeedbackGenerator] = [
      "light": UIImpactFeedbackGenerator(style: .light),
      "medium": UIImpactFeedbackGenerator(style: .medium),
      "heavy": UIImpactFeedbackGenerator(style: .heavy),
      "soft": UIImpactFeedbackGenerator(style: .soft),
      "rigid": UIImpactFeedbackGenerator(style: .rigid),
    ]

    channel.setMethodCallHandler { call, result in
      let kind = call.arguments as? String ?? ""
      switch call.method {
      case "notification":
        let type: UINotificationFeedbackGenerator.FeedbackType
        switch kind {
        case "warning": type = .warning
        case "error": type = .error
        default: type = .success
        }
        notification.notificationOccurred(type)
        notification.prepare()
        result(nil)
      case "impact":
        let generator = impacts[kind] ?? impacts["medium"]!
        generator.impactOccurred()
        generator.prepare()
        result(nil)
      case "selection":
        selection.selectionChanged()
        selection.prepare()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
