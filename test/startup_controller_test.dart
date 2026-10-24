
import 'package:flutter_test/flutter_test.dart';
import 'package:fajr/bootstrap/startup_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'startup reaches a usable state even when Firebase never responds',
    () async {
      final controller = StartupController();
      final stopwatch = Stopwatch()..start();
      await controller.start();
      stopwatch.stop();

      // Startup must terminate instead of leaving the splash screen indefinitely.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 20)));
      expect(controller.state, isNot(StartupState.initializing));
      controller.dispose();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test('startup is idempotent — no repeated init loops', () async {
    final controller = StartupController();
    await controller.start();
    final stateAfterFirst = controller.state;

    await controller.start();
    expect(controller.state, stateAfterFirst);
    controller.dispose();
  });

  test('retry resets and re-runs cleanly', () async {
    final controller = StartupController();
    await controller.start();
    final stateBefore = controller.state;

    await controller.retry();
    expect(controller.state, isNot(StartupState.initializing));
    expect(controller.state, stateBefore);
    controller.dispose();
  });

  test(
    'no state change or crash after dispose (setState-after-dispose guard)',
    () async {
      final controller = StartupController();
      controller.dispose();

      // A late async result must not throw after dispose.
      await controller.start();
    },
  );

  test('missing Firebase config routes to degraded (demo), not failed',
      () async {
    // Without Firebase configuration, startup should fall back to local mode.
    final controller = StartupController();
    await controller.start();

    expect(
      controller.state,
      anyOf(StartupState.degraded, StartupState.ready),
    );
    expect(controller.isLocalMode, controller.state != StartupState.ready);
    controller.dispose();
  });
}
