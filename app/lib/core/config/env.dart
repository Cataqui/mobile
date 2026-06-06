import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(
  path: '.env',
  useConstantCase: true,
  obfuscate: true,
  requireEnvFile: true,
)
abstract final class Env {
  @EnviedField()
  static final String environment = _Env.environment;

  @EnviedField()
  static final String cataquiApiUrl = _Env.cataquiApiUrl;
}
