import 'package:envied/envied.dart';

part 'app_env.g.dart';

@Envied(
  path: '.env',
  useConstantCase: true,
  obfuscate: true,
  requireEnvFile: true,
)
abstract final class AppEnv {
  @EnviedField()
  static final String environment = _AppEnv.environment;

  @EnviedField()
  static final String cataquiApiUrl = _AppEnv.cataquiApiUrl;
}
