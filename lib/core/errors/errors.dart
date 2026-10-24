
import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Typed application error. Raw exceptions are NEVER shown to users.
class AppError implements Exception {
  const AppError(
    this.code, {
    this.message,
    this.cause,
    this.stackTrace,
  });

  final ErrorCode code;
  final String? message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppError($code)';
}

enum ErrorCode {
  // Startup & config
  startupTimeout,
  firebaseUnavailable,
  firebaseNotConfigured,
  corruptedPrefs,

  // Auth
  invalidEmail,
  weakPassword,
  emailInUse,
  wrongCredentials,
  tooManyAttempts,
  sessionExpired,
  userDisabled,
  requiresReauth,
  network,
  authCancelled,

  // Database
  permissionDenied,
  notFound,
  invalidData,
  missingIndex,
  dbTimeout,
  conflict,

  // Business logic
  invalidInput,
  duplicateJoin,
  duplicateRequest,
  selfRequest,
  blocked,
  rateLimited,
  invalidPrayerTime,
  duplicateEvent,
  unauthorized,

  // Platform
  notificationDenied,
  exactAlarmUnavailable,
  locationDenied,
  locationDisabled,
  dialerUnavailable,

  // Fallback
  unexpected,
}

extension ErrorCodeActions on ErrorCode {
  ErrorAction get action => switch (this) {
        ErrorCode.network ||
        ErrorCode.dbTimeout ||
        ErrorCode.firebaseUnavailable =>
          ErrorAction.retry,
        ErrorCode.startupTimeout => ErrorAction.retryOrOffline,
        ErrorCode.sessionExpired ||
        ErrorCode.requiresReauth ||
        ErrorCode.userDisabled =>
          ErrorAction.signInAgain,
        ErrorCode.notificationDenied ||
        ErrorCode.locationDenied ||
        ErrorCode.locationDisabled ||
        ErrorCode.exactAlarmUnavailable ||
        ErrorCode.missingIndex =>
          ErrorAction.openSettings,
        ErrorCode.corruptedPrefs ||
        ErrorCode.notFound ||
        ErrorCode.permissionDenied ||
        ErrorCode.conflict ||
        ErrorCode.duplicateJoin ||
        ErrorCode.duplicateRequest ||
        ErrorCode.rateLimited ||
        ErrorCode.invalidInput ||
        ErrorCode.selfRequest ||
        ErrorCode.blocked =>
          ErrorAction.editInput,
        _ => ErrorAction.contactSupport,
      };
}

enum ErrorAction {
  retry,
  retryOrOffline,
  signInAgain,
  openSettings,
  editInput,
  contactSupport,
}

class ErrorMapper {
  const ErrorMapper._();

  static const Map<ErrorCode, String> _arabicMessages = {
    ErrorCode.startupTimeout: 'استغرقت عملية التحميل وقتًا طويلًا.',
    ErrorCode.firebaseUnavailable: 'تعذّر الاتصال بالخدمات السحابية الآن.',
    ErrorCode.firebaseNotConfigured:
        'لم يتم ضبط Firebase بعد — يعمل التطبيق في الوضع المحلي.',
    ErrorCode.corruptedPrefs: 'بيانات محفوظة تالفة — اختر الإعدادات من جديد.',
    ErrorCode.invalidEmail: 'البريد الإلكتروني غير صحيح.',
    ErrorCode.weakPassword: 'كلمة المرور قصيرة جدًا (6 أحرف على الأقل).',
    ErrorCode.emailInUse: 'هذا البريد مسجّل مسبقًا.',
    ErrorCode.wrongCredentials: 'البريد أو كلمة المرور غير صحيحة.',
    ErrorCode.tooManyAttempts: 'محاولات كثيرة — انتظر قليلًا ثم أعد المحاولة.',
    ErrorCode.sessionExpired: 'انتهت صلاحية الجلسة — سجّل الدخول من جديد.',
    ErrorCode.requiresReauth:
        'لأمان حسابك، سجّل الدخول من جديد لإكمال الإجراء.',
    ErrorCode.userDisabled: 'هذا الحساب معطّل. تواصل مع الدعم.',
    ErrorCode.network: 'لا يوجد اتصال بالإنترنت.',
    ErrorCode.authCancelled: 'تم إلغاء عملية الدخول.',
    ErrorCode.permissionDenied: 'ليس لديك صلاحية لهذا الإجراء.',
    ErrorCode.notFound: 'العنصر المطلوب غير موجود.',
    ErrorCode.invalidData: 'البيانات غير صالحة.',
    ErrorCode.missingIndex:
        'الفهرس قيد الإنشاء على الخادم — أعد المحاولة لاحقًا.',
    ErrorCode.dbTimeout: 'انتهت مهلة الاتصال بقاعدة البيانات.',
    ErrorCode.conflict: 'يتعارض هذا الإجراء مع بيانات موجودة.',
    ErrorCode.invalidInput: 'تحقق من البيانات المدخلة.',
    ErrorCode.duplicateJoin: 'أنت عضو في هذا الفريق بالفعل.',
    ErrorCode.duplicateRequest: 'طلب مماثل قائم بالفعل.',
    ErrorCode.selfRequest: 'لا يمكنك إرسال طلب لنفسك.',
    ErrorCode.blocked: 'لا يمكن إكمال الطلب.',
    ErrorCode.rateLimited: 'طلبات كثيرة جدًا — انتظر دقيقة.',
    ErrorCode.invalidPrayerTime:
        'تعذّر حساب وقت الصلاة — تحقق من المدينة.',
    ErrorCode.duplicateEvent: 'تم تسجيل هذا الحدث مسبقًا.',
    ErrorCode.unauthorized: 'يلزم تسجيل الدخول لتنفيذ هذا الإجراء.',
    ErrorCode.notificationDenied: 'إذن الإشعارات غير متاح.',
    ErrorCode.exactAlarmUnavailable:
        'التنبيهات الدقيقة غير متاحة على هذا الجهاز.',
    ErrorCode.locationDenied: 'إذن الموقع مرفوض — اختر مدينة يدويًا.',
    ErrorCode.locationDisabled: 'خدمة الموقع معطّلة — اختر مدينة يدويًا.',
    ErrorCode.dialerUnavailable: 'لا يمكن فتح تطبيق الاتصال.',
    ErrorCode.unexpected: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
  };

  static String userMessage(AppError error) =>
      error.message ??
      _arabicMessages[error.code] ??
      _arabicMessages[ErrorCode.unexpected]!;

  static AppError map(Object error, {StackTrace? stackTrace}) {
    switch (error) {
      case AppError appError:
        return appError;

      case FirebaseAuthException authError:
        return AppError(
          switch (authError.code) {
            'invalid-email' => ErrorCode.invalidEmail,
            'weak-password' => ErrorCode.weakPassword,
            'email-already-in-use' => ErrorCode.emailInUse,
            'wrong-password' || 'user-not-found' || 'invalid-credential' =>
              ErrorCode.wrongCredentials,
            'too-many-requests' => ErrorCode.tooManyAttempts,
            'user-disabled' => ErrorCode.userDisabled,
            'requires-recent-login' => ErrorCode.requiresReauth,
            'network-request-failed' => ErrorCode.network,
            _ => ErrorCode.unexpected,
          },
          cause: error,
          stackTrace: stackTrace,
        );

      case FirebaseException firebaseError:
        final code = firebaseError.code ?? '';
        final isFirestore = firebaseError.plugin == 'cloud_firestore';

        if (!isFirestore) {
          return AppError(
            code == 'unavailable' || code == 'network-request-failed'
                ? ErrorCode.firebaseUnavailable
                : ErrorCode.unexpected,
            cause: error,
            stackTrace: stackTrace,
          );
        }

        return AppError(
          switch (code) {
            'permission-denied' => ErrorCode.permissionDenied,
            'unavailable' || 'deadline-exceeded' => ErrorCode.dbTimeout,
            'failed-precondition' => ErrorCode.missingIndex,
            'not-found' => ErrorCode.notFound,
            'already-exists' || 'aborted' => ErrorCode.conflict,
            'unauthenticated' => ErrorCode.sessionExpired,
            'invalid-argument' => ErrorCode.invalidData,
            _ => ErrorCode.unexpected,
          },
          cause: error,
          stackTrace: stackTrace,
        );

      case TimeoutException _:
        return AppError(
          ErrorCode.startupTimeout,
          cause: error,
          stackTrace: stackTrace,
        );

      case FormatException _:
        return AppError(
          ErrorCode.corruptedPrefs,
          cause: error,
          stackTrace: stackTrace,
        );

      default:
        return AppError(
          ErrorCode.unexpected,
          cause: error,
          stackTrace: stackTrace,
        );
    }
  }
}

/// Exponential backoff with jitter for retryable operations.
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  final int maxAttempts;
  final Duration baseDelay;

  Future<T> run<T>(
    Future<T> Function() operation, {
    bool retryable = true,
  }) async {
    var attempt = 0;

    while (true) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        final appError = ErrorMapper.map(
          error,
          stackTrace: stackTrace,
        );

        final canRetry = retryable &&
            attempt < maxAttempts &&
            appError.code.action == ErrorAction.retry;

        if (!canRetry) rethrow;

        attempt++;
        final jitter = Random().nextDouble() * 0.3 + 0.85;
        final delay = baseDelay * (pow(2, attempt) * jitter);
        await Future<void>.delayed(delay);
      }
    }
  }
}

/// Always calls onDone, including when the operation fails.
extension SafeAsync<T> on Future<T> {
  Future<void> safe({
    void Function(AppError error)? onError,
    required FutureOr<void> Function() onDone,
    void Function(T value)? onSuccess,
  }) async {
    try {
      final value = await this;
      onSuccess?.call(value);
    } catch (error, stackTrace) {
      onError?.call(
        ErrorMapper.map(error, stackTrace: stackTrace),
      );
    } finally {
      await onDone();
    }
  }
}
