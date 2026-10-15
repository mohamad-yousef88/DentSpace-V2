import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../di/injection.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

/// Owns the full FCM token lifecycle:
///   1. Requests notification permission.
///   2. Fetches the current device token.
///   3. Pushes it to the backend via [AuthBloc].
///   4. Re-syncs whenever the token rotates or the user logs in.
///
/// Deliberately decoupled from `NotificationService` (which handles
/// foreground presentation) to respect SRP.
class FcmSyncService {
  FcmSyncService._();
  static final FcmSyncService instance = FcmSyncService._();

  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: permission denied');
        return;
      }

      // Push current token once authenticated
      _syncCurrentToken();

      // React to token rotation
      messaging.onTokenRefresh.listen(_pushToken);

      // React to login
      getIt<AuthBloc>().stream.listen((state) {
        if (state.status == AuthStatus.authenticated) {
          _syncCurrentToken();
        }
      });
    } catch (e, st) {
      debugPrint('FcmSyncService.start failed: $e\n$st');
    }
  }

  Future<void> _syncCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      _pushToken(token);
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
    }
  }

  void _pushToken(String? token) {
    if (token == null || token.isEmpty) return;
    getIt<AuthBloc>().add(SyncFcmTokenEvent(token));
  }
}