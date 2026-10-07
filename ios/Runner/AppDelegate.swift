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
    registerPasteboardChannel(engineBridge)
    registerAppReviewChannel(engineBridge)
  }

  /// Kanal `einundzwanzig/pasteboard`: liefert ein Bild aus der
  /// Zwischenablage als PNG (z. B. einen gescreenshoteten Cashu-Token-QR).
  private func registerPasteboardChannel(_ engineBridge: FlutterImplicitEngineBridge) {
    let channel = FlutterMethodChannel(
      name: "einundzwanzig/pasteboard",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "image" else {
        result(FlutterMethodNotImplemented)
        return
      }
      clipboardImage { data in
        result(data)
      }
    }
  }

  /// Kanal `einundzwanzig/review` fuer den App-Review-Demo-Login.
  ///
  /// `isTestFlight` prueft den Receipt: Bei TestFlight UND in
  /// App-Review-Sessions liegt ein Sandbox-Receipt vor, bei echten
  /// App-Store-Installationen nicht. Genau die beiden Faelle sollen den
  /// Demo-Login angeboten bekommen — AltStore-/Release-Nutzer nie.
  private func registerAppReviewChannel(_ engineBridge: FlutterImplicitEngineBridge) {
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppReviewChannel") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "einundzwanzig/review",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isTestFlight":
        let isSandbox = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        result(isSandbox)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

private func clipboardImage(_ done: @escaping (FlutterStandardTypedData?) -> Void) {
  let board = UIPasteboard.general
  if let image = board.image {
    done(pngBytes(image))
    return
  }
  guard let provider = board.itemProviders.first(where: { $0.canLoadObject(ofClass: UIImage.self) }) else {
    done(nil)
    return
  }
  provider.loadObject(ofClass: UIImage.self) { object, _ in
    let data = (object as? UIImage).flatMap(pngBytes)
    DispatchQueue.main.async {
      done(data)
    }
  }
}

private func pngBytes(_ image: UIImage) -> FlutterStandardTypedData? {
  guard let data = fittedImage(image, maxSide: 2000).pngData() else { return nil }
  return FlutterStandardTypedData(bytes: data)
}

private func fittedImage(_ image: UIImage, maxSide: CGFloat) -> UIImage {
  let size = image.size
  let longest = max(size.width, size.height)
  if longest <= maxSide || longest <= 0 { return image }
  let scale = maxSide / longest
  let target = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))
  let format = UIGraphicsImageRendererFormat.default()
  format.scale = 1
  format.opaque = true
  return UIGraphicsImageRenderer(size: target, format: format).image { _ in
    UIColor.white.setFill()
    UIBezierPath(rect: CGRect(origin: .zero, size: target)).fill()
    image.draw(in: CGRect(origin: .zero, size: target))
  }
}
