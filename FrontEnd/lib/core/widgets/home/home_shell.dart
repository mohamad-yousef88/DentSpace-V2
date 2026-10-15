import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../../features/notifications/presentation/bloc/notifications_event.dart';
import '../../../features/notifications/presentation/bloc/notifications_state.dart';
import '../../localization/localization_cubit.dart';
import '../../router/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'home_drawer.dart';
import 'models/home_tab.dart';

/// Shared scaffolding for both Patient and Doctor home screens.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.tabs});

  final List<HomeTab> tabs;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Prime the badge count on first render. NotificationsBloc is a
    // singleton (see injection.dart), so the count stays in sync with
    // the standalone NotificationsPage.
    GetIt.instance<NotificationsBloc>().add(const LoadNotificationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final currentTab = widget.tabs[_currentIndex];

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: const HomeDrawer(),
      appBar: AppBar(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.lightTextPrimary,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'DentSpace',
              style: AppTextStyles.titleLarge.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: const [
          _NotificationsBell(),
          SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: currentTab.page,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor:
        isDark ? AppColors.darkSurface : AppColors.lightSurface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        elevation: 3,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: widget.tabs
            .map(
              (tab) => NavigationDestination(
            icon: Icon(tab.icon),
            selectedIcon:
            Icon(tab.activeIcon, color: AppColors.primary),
            label: isArabic ? tab.labelAr : tab.labelEn,
          ),
        )
            .toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AppBar bell with Material 3 Badge
// ═══════════════════════════════════════════════════════════════
class _NotificationsBell extends StatelessWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bloc = GetIt.instance<NotificationsBloc>();

    return BlocBuilder<NotificationsBloc, NotificationsState>(
      bloc: bloc,
      buildWhen: (prev, curr) => prev.unreadCount != curr.unreadCount,
      builder: (context, state) {
        final count = state.unreadCount;
        return IconButton(
          onPressed: () => context.push(Routes.notifications),
          icon: Badge(
            isLabelVisible: count > 0,
            backgroundColor: AppColors.error,
            label: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        );
      },
    );
  }
}