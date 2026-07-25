import 'package:cataqui_app/app.dart';
import 'package:cataqui_app/core/app_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final providerContainer = ProviderContainer();
  await AppBootstrap.setup(providerContainer: providerContainer);

  runApp(UncontrolledProviderScope(container: providerContainer, child: const CataquiApp()));
}
