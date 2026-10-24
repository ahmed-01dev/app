
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/errors/errors.dart';
import '../core/theme/fajr_theme.dart';
import 'startup_controller.dart';

/// Splash screen driven by the finite startup FSM. The spinner is BOUNDED:
/// every state transition has an exit path — there is no path that waits
/// forever.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onNext});

  /// Called exactly once with the final FSM state.
  final void Function(StartupState state) onNext;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final StartupController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StartupController();
    _controller.addListener(_route);
    // Fire-and-forget: errors flow through the FSM state, never an
    // unhandled async callback.
    _controller.start();
  }

  void _route() {
    if (!mounted) return;
    final state = _controller.state;
    if (state == StartupState.initializing) return;
    _controller.removeListener(_route);
    widget.onNext(state);
  }

  @override
  void dispose() {
    _controller.removeListener(_route);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: FajrTheme.navyDeep,
        body: Consumer<StartupController>(
          builder: (context, controller, _) => switch (controller.state) {
            StartupState.initializing ||
            StartupState.ready ||
            StartupState.degraded => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('فَجْر', style: FajrTheme.splashTitle),
                  SizedBox(height: 24),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: FajrTheme.emerald,
                    ),
                  ),
                ],
              ),
            ),
            StartupState.failed => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      color: FajrTheme.gold,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.lastError == null
                          ? 'تعذّر بدء التطبيق.'
                          : ErrorMapper.userMessage(controller.lastError!),
                      textAlign: TextAlign.center,
                      style: FajrTheme.body,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: controller.retry,
                      child: const Text('إعادة المحاولة'),
                    ),
                    TextButton(
                      onPressed: () => widget.onNext(StartupState.degraded),
                      child: const Text('المتابعة في الوضع المحلي'),
                    ),
                  ],
                ),
              ),
            ),
          },
        ),
      ),
    );
  }
}
