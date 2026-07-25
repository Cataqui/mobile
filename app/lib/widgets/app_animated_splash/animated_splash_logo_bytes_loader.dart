part of 'app_animated_splash.dart';

class _SplashLogoBytesLoader extends BytesLoader {
  const _SplashLogoBytesLoader(this.assetName);

  final String assetName;

  AssetBundle _resolveBundle(BuildContext? context) {
    if (context == null) return rootBundle;

    return DefaultAssetBundle.of(context);
  }

  @override
  Object cacheKey(BuildContext? context) {
    return (assetName: assetName, assetBundle: _resolveBundle(context));
  }

  @override
  Future<ByteData> loadBytes(BuildContext? context) {
    return _resolveBundle(context).load(assetName);
  }

  @override
  String toString() => 'CataquiSplashLogo($assetName)';
}
