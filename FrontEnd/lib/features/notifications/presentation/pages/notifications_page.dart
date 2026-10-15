import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/notifications/notification_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../widgets/notification_tile.dart';

/// Unified notifications screen.
///
/// Modes:
///   • `embedded = false` (default): full page with [Scaffold] + [AppBar]
///     — pushed from the AppBar bell or the drawer.
///   • `embedded = true`: content-only — used as a bottom-nav tab inside
///     [HomeShell].
///
/// Both modes render identical content; only the chrome differs.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.embedded = false});

  /// Skip the outer [Scaffold] and [AppBar] when embedded in a shell.
  final bool embedded;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<NotificationsBloc>();
    _bloc.add(const LoadNotificationsEvent());
  }

  // ═══════════════════════════════════════════════════════════════
  void _onNotificationTap(AppNotification n) {
    if (!n.isRead) _bloc.add(MarkNotificationReadEvent(n.id));
    final route = NotificationRouter.routeFor(n.type, payload: n.payload);
    if (route != null && mounted) {
      context.push(route);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ─── Shared body ────────────────────────────────────
    final body = BlocConsumer<NotificationsBloc, NotificationsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.items.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state.items.isEmpty) {
          return _EmptyState(isArabic: isArabic, isDark: isDark);
        }

        return Column(
          children: [
            // Action bar — visible in both modes for consistency
            _ActionBar(
              state: state,
              isArabic: isArabic,
              isDark: isDark,
              onMarkAll: () =>
                  _bloc.add(const MarkAllNotificationsReadEvent()),
              onDeleteRead: () =>
                  _bloc.add(const DeleteReadNotificationsEvent()),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async =>
                    _bloc.add(const LoadNotificationsEvent()),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final n = state.items[i];
                    return NotificationTile(
                      notification: n,
                      isArabic: isArabic,
                      isDark: isDark,
                      onTap: () => _onNotificationTap(n),
                      onDelete: () =>
                          _bloc.add(DeleteNotificationEvent(n.id)),
                    )
                        .animate(delay: (i * 40).ms)
                        .fadeIn(duration: 300.ms);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    // ─── Mode: embedded tab ─────────────────────────────
    if (widget.embedded) {
      return BlocProvider.value(value: _bloc, child: body);
    }

    // ─── Mode: standalone full page ─────────────────────
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isArabic
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            isArabic ? 'الإشعارات' : 'Notifications',
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: body,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Action bar (bulk actions)
// ═══════════════════════════════════════════════════════════════
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.state,
    required this.isArabic,
    required this.isDark,
    required this.onMarkAll,
    required this.onDeleteRead,
  });

  final NotificationsState state;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onMarkAll;
  final VoidCallback onDeleteRead;

  @override
  Widget build(BuildContext context) {
    final hasUnread = state.unreadCount > 0;
    final hasRead = state.items.any((n) => n.isRead);
    if (!hasUnread && !hasRead) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          if (hasUnread)
            TextButton.icon(
              onPressed: onMarkAll,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(isArabic ? 'تعليم الكل كمقروء' : 'Mark all read'),
            ),
          const Spacer(),
          if (hasRead)
            IconButton(
              tooltip: isArabic ? 'حذف المقروءة' : 'Delete read',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: onDeleteRead,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Empty state
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isArabic, required this.isDark});
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
                size: 56,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
            const SizedBox(height: 24),
            Text(
              isArabic ? 'لا توجد إشعارات' : 'No notifications',
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 10),
            Text(
              isArabic
                  ? 'ستظهر هنا إشعارات طلبات الحجز والموافقات.'
                  : 'Booking requests and approvals will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.5,
              ),
            ).animate(delay: 350.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}