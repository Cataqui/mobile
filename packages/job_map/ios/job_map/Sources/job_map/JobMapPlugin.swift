import Flutter
import Foundation

public class JobMapPlugin: NSObject, FlutterPlugin {
  private var bridge: JobMapFrameBridge?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = JobMapPlugin()
    plugin.bridge = JobMapFrameBridge(
      messenger: registrar.messenger(),
      textureRegistry: registrar.textures())
    JobMapHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: plugin.bridge)
    registrar.publish(plugin)
  }

  deinit {
    try? bridge?.disposeFrames()
  }
}
