import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private(set) var googleMapsServices: NSObjectProtocol?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard
      let googleMapsAPIKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey")
        as? String,
      !googleMapsAPIKey.isEmpty,
      googleMapsAPIKey != "$(GOOGLE_MAPS_API_KEY)",
      googleMapsAPIKey != "PASTE_IOS_API_KEY_HERE"
    else {
      fatalError("GOOGLE_MAPS_API_KEY must be configured in ios/Flutter/Secrets.xcconfig.")
    }
    GMSServices.provideAPIKey(googleMapsAPIKey)
    googleMapsServices = GMSServices.sharedServices()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
