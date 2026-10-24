
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fajr/core/errors/errors.dart';

void main() {
  group('ErrorMapper.map', () {
    test('invalid email maps to invalidEmail', () {
      final error = FirebaseAuthException(code: 'invalid-email');

      final result = ErrorMapper.map(error);

      expect(result.code, ErrorCode.invalidEmail);
      expect(ErrorMapper.userMessage(result), contains('البريد'));
    });

    test('weak password maps to weakPassword', () {
      final error = FirebaseAuthException(code: 'weak-password');

      expect(ErrorMapper.map(error).code, ErrorCode.weakPassword);
    });

    test('email already in use maps correctly', () {
      final error = FirebaseAuthException(code: 'email-already-in-use');

      expect(ErrorMapper.map(error).code, ErrorCode.emailInUse);
    });

    test('too many attempts is not retryable', () {
      final error = FirebaseAuthException(code: 'too-many-requests');
      final result = ErrorMapper.map(error);

      expect(result.code, ErrorCode.tooManyAttempts);
      expect(result.code.action, isNot(ErrorAction.retry));
    });

    test('network auth failure is retryable', () {
      final error = FirebaseAuthException(
        code: 'network-request-failed',
      );
      final result = ErrorMapper.map(error);

      expect(result.code, ErrorCode.network);
      expect(result.code.action, ErrorAction.retry);
    });

    test('Firestore permission denied maps correctly', () {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'denied',
      );

      final result = ErrorMapper.map(error);

      expect(result.code, ErrorCode.permissionDenied);
      expect(result.code.action, ErrorAction.editInput);
    });

    test('Firestore failed precondition maps to missingIndex', () {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
        message: 'index',
      );

      expect(ErrorMapper.map(error).code, ErrorCode.missingIndex);
    });

    test('Firestore unavailable maps to dbTimeout', () {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );

      expect(ErrorMapper.map(error).code, ErrorCode.dbTimeout);
    });

    test('timeout maps to startupTimeout', () {
      final result = ErrorMapper.map(TimeoutException('timeout'));

      expect(result.code, ErrorCode.startupTimeout);
      expect(result.code.action, ErrorAction.retryOrOffline);
    });

    test('FormatException maps to corruptedPrefs', () {
      final result = ErrorMapper.map(
        const FormatException('bad'),
      );

      expect(result.code, ErrorCode.corruptedPrefs);
    });

    test('unknown errors map to unexpected', () {
      final result = ErrorMapper.map(StateError('unknown'));

      expect(result.code, ErrorCode.unexpected);
      expect(
        ErrorMapper.userMessage(result),
        contains('خطأ غير متوقع'),
      );
    });

    test('every error code has a non-empty Arabic message', () {
      for (final code in ErrorCode.values) {
        final result = ErrorMapper.userMessage(AppError(code));

        expect(
          result,
          isNotEmpty,
          reason: 'Missing message for $code',
        );
        expect(
          code.action,
          isA<ErrorAction>(),
          reason: 'Missing action for $code',
        );
      }
    });
  });

  group('SafeAsync', () {
    test('onDone runs on success', () async {
      var done = false;

      await Future<void>.value().safe(
        onDone: () => done = true,
      );

      expect(done, isTrue);
    });

    test('onDone runs when operation throws', () async {
      var done = false;
      AppError? caught;

      await Future<void>.error(StateError('boom')).safe(
        onError: (error) => caught = error,
        onDone: () => done = true,
      );

      expect(done, isTrue);
      expect(caught, isNotNull);
      expect(caught!.code, ErrorCode.unexpected);
    });

    test('onSuccess receives the result', () async {
      int? received;

      await Future<int>.value(42).safe(
        onSuccess: (value) => received = value,
        onDone: () {},
      );

      expect(received, 42);
    });
  });

  group('RetryPolicy', () {
    test('retries network errors and eventually succeeds', () async {
      const policy = RetryPolicy(
        baseDelay: Duration(milliseconds: 1),
      );
      var attempts = 0;

      final result = await policy.run<int>(() async {
        attempts++;

        if (attempts < 3) {
          throw FirebaseAuthException(
            code: 'network-request-failed',
          );
        }

        return 42;
      });

      expect(result, 42);
      expect(attempts, 3);
    });

    test('does not retry when retryable is false', () async {
      const policy = RetryPolicy(
        baseDelay: Duration(milliseconds: 1),
      );
      var attempts = 0;

      await expectLater(
        policy.run<int>(
          () async {
            attempts++;
            throw FirebaseAuthException(
              code: 'network-request-failed',
            );
          },
          retryable: false,
        ),
        throwsA(isA<FirebaseAuthException>()),
      );

      expect(attempts, 1);
    });

    test('stops after maxAttempts retries', () async {
      const policy = RetryPolicy(
        maxAttempts: 2,
        baseDelay: Duration(milliseconds: 1),
      );
      var attempts = 0;

      await expectLater(
        policy.run<int>(() async {
          attempts++;
          throw FirebaseAuthException(
            code: 'network-request-failed',
          );
        }),
        throwsA(isA<FirebaseAuthException>()),
      );

      expect(attempts, 3);
    });
  });
}
