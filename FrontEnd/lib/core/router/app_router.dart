import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/pages/about_page.dart';
import '../../features/appointments/presentation/bloc/appointments_bloc.dart';
import '../../features/appointments/presentation/pages/achievements_page.dart';
import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/home/doctor_home/presentation/pages/doctor_home_page.dart';
import '../../features/home/patient_home/presentation/pages/patient_home_page.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';
import '../../features/orders/presentation/pages/hidden_orders_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/patient_cases/presentation/bloc/cases_bloc.dart';
import '../../features/patient_cases/presentation/pages/available_cases_page.dart';
import '../../features/patient_cases/presentation/pages/case_detail_page.dart';
import '../../features/patient_cases/presentation/pages/cases_list_page.dart';
import '../../features/patient_cases/presentation/pages/diagnosis_form_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/tools/presentation/bloc/tools_bloc.dart';
import '../../features/tools/presentation/pages/create_tool_page.dart';
import '../../features/tools/presentation/pages/edit_tool_page.dart';
import '../../features/tools/presentation/pages/my_tools_page.dart';
import '../../features/tools/presentation/pages/tool_detail_page.dart';
import '../../features/tools/presentation/pages/tools_market_page.dart';
import 'routes.dart';

class AppRouter {
  AppRouter._();
  static final AppRouter instance = AppRouter._();

  late final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      // ═══════════════════════════════════════════════════════
      // Entry
      // ═══════════════════════════════════════════════════════
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // ═══════════════════════════════════════════════════════
      // Auth
      // ═══════════════════════════════════════════════════════
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => BlocProvider.value(
          value: GetIt.instance<AuthBloc>(),
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) => BlocProvider.value(
          value: GetIt.instance<AuthBloc>(),
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: Routes.verifyEmail,
        name: 'verifyEmail',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return BlocProvider.value(
            value: GetIt.instance<AuthBloc>(),
            child: VerifyEmailPage(email: email),
          );
        },
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => BlocProvider.value(
          value: GetIt.instance<AuthBloc>(),
          child: const ForgotPasswordPage(),
        ),
      ),

      // ═══════════════════════════════════════════════════════
      // Home
      // ═══════════════════════════════════════════════════════
      GoRoute(
        path: Routes.patientHome,
        name: 'patientHome',
        builder: (context, state) => BlocProvider.value(
          value: GetIt.instance<AuthBloc>(),
          child: const PatientHomePage(),
        ),
      ),
      GoRoute(
        path: Routes.doctorHome,
        name: 'doctorHome',
        builder: (context, state) => BlocProvider.value(
          value: GetIt.instance<AuthBloc>(),
          child: const DoctorHomePage(),
        ),
      ),

      // ═══════════════════════════════════════════════════════
      // Cases — static first, then dynamic
      // ═══════════════════════════════════════════════════════
      GoRoute(
        path: Routes.casesList,
        name: 'casesList',
        builder: (context, state) => BlocProvider(
          create: (_) => GetIt.instance<CasesBloc>(),
          child: const CasesListPage(),
        ),
      ),
      GoRoute(
        path: Routes.caseNew,
        name: 'caseNew',
        builder: (context, state) => BlocProvider(
          create: (_) => GetIt.instance<CasesBloc>(),
          child: const DiagnosisFormPage(),
        ),
      ),
      GoRoute(
        path: Routes.casesAvailable,
        name: 'casesAvailable',
        builder: (context, state) => const AvailableCasesPage(),
      ),
      GoRoute(
        path: '/cases/:id',
        name: 'caseDetails',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return BlocProvider(
            create: (_) => GetIt.instance<CasesBloc>(),
            child: CaseDetailPage(caseId: id),
          );
        },
      ),

      // ═══════════════════════════════════════════════════════
      // Appointments
      // ═══════════════════════════════════════════════════════
      GoRoute(
        path: Routes.appointments,
        name: 'appointments',
        builder: (context, state) => BlocProvider(
          create: (_) => GetIt.instance<AppointmentsBloc>(),
          child: const AppointmentsPage(),
        ),
      ),
      GoRoute(
        path: Routes.achievements,
        name: 'achievements',
        builder: (context, state) => BlocProvider(
          create: (_) => GetIt.instance<AppointmentsBloc>(),
          child: const AchievementsPage(),
        ),
      ),

      // ═══════════════════════════════════════════════════════
      // Notifications
      // ═══════════════════════════════════════════════════════
      GoRoute(
        path: Routes.notifications,
        name: 'notifications',
        builder: (context, state) => BlocProvider(
          create: (_) => GetIt.instance<NotificationsBloc>(),
          child: const NotificationsPage(),
        ),
      ),

      // ═══════════════════════════════════════════════════════
      // Profile / Support / About
      // ═══════════════════════════════════════════════════════
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: Routes.support,
        name: 'support',
        builder: (context, state) => const SupportPage(),
      ),
      GoRoute(
        path: Routes.about,
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),

      // ═══════════════════════════════════════════════════════
      // Tools — static first (`/tools/mine`, `/tools/new`)
      //         then dynamic (`/tools/:id`, `/tools/:id/edit`)
      // ═══════════════════════════════════════════════════════
      GoRoute(
        path: Routes.toolsMarket, // '/tools'
        name: 'toolsMarket',
        builder: (context, state) => BlocProvider(
          create: (_) => GetIt.instance<ToolsBloc>(),
          child: const ToolsMarketPage(),
        ),
      ),
      GoRoute(
        path: Routes.myTools, // '/tools/mine'
        name: 'myTools',
        builder: (context, state) => BlocProvider(
          create: (_) => GetIt.instance<ToolsBloc>(),
          child: const MyToolsPage(),
        ),
      ),
      GoRoute(
        path: Routes.toolNew, // '/tools/new'
        name: 'toolNew',
        builder: (context, state) => BlocProvider(
          create: (_) => GetIt.instance<ToolsBloc>(),
          child: const CreateToolPage(),
        ),
      ),
      GoRoute(
        path: '/tools/:id',
        name: 'toolDetails',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return BlocProvider(
            create: (_) => GetIt.instance<ToolsBloc>(),
            child: ToolDetailPage(toolId: id),
          );
        },
      ),
      GoRoute(
        path: '/tools/:id/edit',
        name: 'toolEdit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return BlocProvider(
            create: (_) => GetIt.instance<ToolsBloc>(),
            child: EditToolPage(toolId: id),
          );
        },
      ),

      // ═══════════════════════════════════════════════════════
      // Orders — static first (`/orders/hidden`)
      //          then dynamic (`/orders/:id`)
      // ═══════════════════════════════════════════════════════
      GoRoute(
        path: Routes.orders, // '/orders'
        name: 'orders',
        builder: (context, state) => BlocProvider(
          create: (_) => GetIt.instance<OrdersBloc>(),
          child: const OrdersPage(),
        ),
      ),
      GoRoute(
        path: Routes.hiddenOrders, // '/orders/hidden' — MUST precede :id
        name: 'hiddenOrders',
        builder: (context, state) => BlocProvider(
          create: (_) => GetIt.instance<OrdersBloc>(),
          child: const HiddenOrdersPage(),
        ),
      ),
      GoRoute(
        path: '/orders/:id',
        name: 'orderDetails',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return BlocProvider(
            create: (_) => GetIt.instance<OrdersBloc>(),
            child: OrderDetailPage(orderId: id),
          );
        },
      ),
    ],

    // ═══════════════════════════════════════════════════════════
    // Error fallback — shown when no route matches
    // ═══════════════════════════════════════════════════════════
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Route Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'No route defined for:\n${state.uri}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(Routes.splash),
                  child: const Text('Back to splash'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}