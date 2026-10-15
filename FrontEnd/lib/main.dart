import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/cache/hive_initializer.dart';
import 'core/config/environment.dart';
import 'core/di/injection.dart';
import 'core/notifications/fcm_sync_service.dart';
import 'core/notifications/notification_service.dart';
import 'features/appointments/presentation/bloc/appointments_bloc.dart';
import 'features/appointments/presentation/bloc/appointments_event.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // ─── Local cache (must precede DI: DI opens the box) ───
    await HiveInitializer.init();

    // ─── DI ──────────────────────────────────────────────
    await configureDependencies();

    // ─── Firebase + notifications (soft-fail) ────────────
    try {
      await Firebase.initializeApp();

      await NotificationService.instance.init();
      await FcmSyncService.instance.start();

      // ── FCM → refresh relevant features ────────────────
      NotificationService.instance.messages.listen((msg) {
        debugPrint('FCM received in foreground: ${msg.messageId}');

        getIt<NotificationsBloc>().add(const LoadNotificationsEvent());

        try {
          getIt<AppointmentsBloc>().add(const LoadDoctorStatsEvent());
        } catch (_) {
          // AppointmentsBloc is a Factory — fresh instance, no harm.
        }
      });
    } catch (e, st) {
      debugPrint('Firebase init skipped: $e\n$st');
    }

    runApp(const DentSpaceApp());
  } catch (e, st) {
    debugPrint('STARTUP FAILURE: $e\n$st');
    runApp(_StartupErrorApp(message: '$e'));
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444),
                      size: 72,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'DentSpace — Startup Error',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SelectableText(
                      'Env: ${Environment.current.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}