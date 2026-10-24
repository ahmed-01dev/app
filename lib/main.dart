
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app.dart';
import 'bootstrap/splash_screen.dart';
import 'bootstrap/startup_controller.dart';
import 'core/logging/app_logger.dart';

final GlobalKey<NavigatorState> _navigatorKey =
    GlobalKey<NavigatorState>();

void main() {
  AppLogger.init(debugMode: kDebugMode);
  runApp(const FajrBootstrap());
}

class FajrBootstrap extends StatelessWidget {
  const FajrBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: SplashScreen(
        onNext: (state) {
          final isLocalMode = state != StartupState.ready;

          _navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => FajrApp(
                isLocalMode: isLocalMode,
              ),
            ),
          );
        },
      ),
    );
  }
}
