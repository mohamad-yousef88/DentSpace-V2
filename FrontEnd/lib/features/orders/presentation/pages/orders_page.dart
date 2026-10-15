import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/cache/cache_service.dart';
import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/order.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';
import '../widgets/order_card.dart';

/// Unified orders page for both roles.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrdersBloc _bloc;

  int _roleIndex = 0; // 0 = seller, 1 = buyer
  int _statusIndex = 0; // 0 = all, 1 = pending, 2 = approved, 3 = completed

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<OrdersBloc>();
    _reload();
  }

  String get _role => _roleIndex == 0 ? 'seller' : 'buyer';

  OrderStatus? get _statusFilter {
    switch (_statusIndex) {
      case 1:
        return OrderStatus.pending;
      case 2:
        return OrderStatus.approved;
      case 3:
        return OrderStatus.completed;
      default:
        return null;
    }
  }

  void _reload() {
    _bloc.add(LoadOrdersEvent(role: _role, status: _statusFilter));
  }

  // ═══════════════════════════════════════════════════════════════
  // Confirmation dialogs
  // ═══════════════════════════════════════════════════════════════
  Future<void> _confirmApprove(Order o) async {
    final ok = await _confirm(
      titleAr: 'قبول الطلب',
      titleEn: 'Approve order',
      bodyAr: 'سيتم حجز الأداة للمشتري ورفض الطلبات الأخرى.',
      bodyEn: 'The tool will be reserved for this buyer.',
      actionAr: 'قبول',
      actionEn: 'Approve',
      actionColor: AppColors.success,
    );
    if (ok == true) _bloc.add(ApproveOrderEvent(o.id));
  }

  Future<void> _confirmReject(Order o) async {
    final ok = await _confirm(
      titleAr: 'رفض الطلب',
      titleEn: 'Reject order',
      bodyAr: 'هل تريد رفض طلب الشراء؟',
      bodyEn: 'Reject this purchase request?',
      actionAr: 'رفض',
      actionEn: 'Reject',
      actionColor: AppColors.error,
    );
    if (ok == true) _bloc.add(RejectOrderEvent(o.id));
  }

  Future<void> _confirmComplete(Order o) async {
    final ok = await _confirm(
      titleAr: 'تأكيد البيع',
      titleEn: 'Mark as sold',
      bodyAr: 'سيتم تعليم الأداة كمبيعة نهائياً.',
      bodyEn: 'The tool will be marked as sold.',
      actionAr: 'تأكيد',
      actionEn: 'Confirm',
      actionColor: AppColors.success,
    );
    if (ok == true) _bloc.add(CompleteOrderEvent(o.id));
  }

  Future<void> _confirmCancel(Order o) async {
    final ok = await _confirm(
      titleAr: 'إلغاء الطلب',
      titleEn: 'Cancel order',
      bodyAr: 'هل تريد إلغاء هذا الطلب؟',
      bodyEn: 'Cancel this order?',
      actionAr: 'إلغاء',
      actionEn: 'Cancel',
      actionColor: AppColors.error,
    );
    if (ok == true) _bloc.add(CancelOrderEvent(o.id));
  }

  Future<bool?> _confirm({
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
    required String actionAr,
    required String actionEn,
    required Color actionColor,
  }) {
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(
          isArabic ? titleAr : titleEn,
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          isArabic ? bodyAr : bodyEn,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'رجوع' : 'Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: actionColor),
            child: Text(isArabic ? actionAr : actionEn),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(int id) async {
    final changed = await context.push<bool>(Routes.orderDetails(id));
    if (changed == true && mounted) _reload();
  }

  // ─── Hide / clear history ────────────────────────────────
  void _hideOrder(Order o) {
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';
    _bloc.add(HideOrderEvent(o.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          isArabic ? 'تم الإخفاء من القائمة' : 'Removed from list',
        ),
        action: SnackBarAction(
          label: isArabic ? 'تراجع' : 'Undo',
          onPressed: () => _bloc.add(UnhideOrderEvent(o.id)),
        ),
      ),);
  }

  Future<void> _confirmClearHistory() async {
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(
          isArabic ? 'مسح السجل' : 'Clear history',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          isArabic
              ? 'سيتم إخفاء جميع الطلبات المنتهية من القائمة. الطلبات النشطة لن تتأثر.'
              : 'All terminal orders will be hidden. Active orders are unaffected.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'رجوع' : 'Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isArabic ? 'مسح' : 'Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      _bloc.add(const ClearOrderHistoryEvent());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            isArabic ? 'الطلبات' : 'Orders',
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          // ★ Options menu — opens Hidden History / clear visible history
          actions: [
            BlocBuilder<OrdersBloc, OrdersState>(
              builder: (context, state) {
                final hasTerminal =
                state.orders.any((o) => !o.status.isActive);
                final hasHidden =
                    GetIt.instance<CacheService>().allHiddenOrderIds().isNotEmpty;

                if (!hasTerminal && !hasHidden) {
                  return const SizedBox.shrink();
                }

                return PopupMenuButton<String>(
                  tooltip: isArabic ? 'خيارات' : 'Options',
                  onSelected: (v) {
                    if (v == 'clear') _confirmClearHistory();
                    if (v == 'hidden') {
                      context.push(Routes.hiddenOrders);
                    }
                  },
                  itemBuilder: (_) => [
                    if (hasHidden)
                      PopupMenuItem(
                        value: 'hidden',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.restore_from_trash_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isArabic
                                  ? 'السجل المخفي'
                                  : 'Hidden history',
                            ),
                          ],
                        ),
                      ),
                    if (hasTerminal)
                      PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cleaning_services_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isArabic
                                  ? 'مسح السجل الظاهر'
                                  : 'Clear visible history',
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // ─── Role segmented bar ─────────────────────
            _SegmentedBar(
              index: _roleIndex,
              isDark: isDark,
              labels: [
                isArabic ? 'الواردة' : 'Incoming',
                isArabic ? 'مشترياتي' : 'My Purchases',
              ],
              onChanged: (i) {
                setState(() => _roleIndex = i);
                _reload();
              },
            ),
            // ─── Status segmented bar ───────────────────
            _SegmentedBar(
              index: _statusIndex,
              isDark: isDark,
              labels: [
                isArabic ? 'الكل' : 'All',
                isArabic ? 'قيد الانتظار' : 'Pending',
                isArabic ? 'معتمد' : 'Approved',
                isArabic ? 'مكتمل' : 'Completed',
              ],
              onChanged: (i) {
                setState(() => _statusIndex = i);
                _reload();
              },
            ),

            // ─── List ───────────────────────────────────
            Expanded(
              child: BlocConsumer<OrdersBloc, OrdersState>(
                listenWhen: (p, c) =>
                p.successMessage != c.successMessage ||
                    p.errorMessage != c.errorMessage,
                listener: (context, state) {
                  final map = {
                    'order_approved':
                    isArabic ? 'تم قبول الطلب' : 'Order approved',
                    'order_rejected':
                    isArabic ? 'تم رفض الطلب' : 'Order rejected',
                    'order_completed':
                    isArabic ? 'تم تأكيد البيع' : 'Order completed',
                    'order_cancelled':
                    isArabic ? 'تم إلغاء الطلب' : 'Order cancelled',
                  };
                  if (state.successMessage != null &&
                      map.containsKey(state.successMessage)) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text(map[state.successMessage]!),
                        backgroundColor: AppColors.success,
                      ),);
                    _bloc.add(const ClearOrderFeedbackEvent());
                    _reload();
                    return;
                  }
                  if (state.errorMessage != null) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text(state.errorMessage!),
                        backgroundColor: AppColors.error,
                      ),);
                    _bloc.add(const ClearOrderFeedbackEvent());
                  }
                },
                builder: (context, state) {
                  if (state.isLoading && state.orders.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  if (state.orders.isEmpty) {
                    return _EmptyState(
                      isArabic: isArabic,
                      isDark: isDark,
                      isSeller: _roleIndex == 0,
                      hasFilter: _statusIndex != 0,
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => _reload(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: state.orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final o = state.orders[i];
                        final isSeller = _roleIndex == 0;

                        final canApprove = isSeller && o.status.isPending;
                        final canReject = isSeller && o.status.isPending;
                        final canComplete = isSeller && o.status.isApproved;
                        final canCancel =
                            (!isSeller && o.status.isActive) ||
                                (isSeller && o.status.isApproved);

                        // ★ Hide available only for terminal orders.
                        final canHide = !o.status.isActive;

                        return OrderCard(
                          key: ValueKey(o.id),
                          order: o,
                          isSellerView: isSeller,
                          isSubmitting: state.isSubmitting,
                          onTap: () => _openDetail(o.id),
                          onApprove:
                          canApprove ? () => _confirmApprove(o) : null,
                          onReject:
                          canReject ? () => _confirmReject(o) : null,
                          onComplete:
                          canComplete ? () => _confirmComplete(o) : null,
                          onCancel:
                          canCancel ? () => _confirmCancel(o) : null,
                          onHide: canHide ? () => _hideOrder(o) : null,
                        )
                            .animate(delay: (i * 50).ms)
                            .fadeIn(duration: 300.ms)
                            .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 300.ms,
                          curve: Curves.easeOutCubic,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Segmented bar
// ═══════════════════════════════════════════════════════════════
class _SegmentedBar extends StatelessWidget {
  const _SegmentedBar({
    required this.index,
    required this.labels,
    required this.onChanged,
    required this.isDark,
  });
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          segments: [
            for (var i = 0; i < labels.length; i++)
              ButtonSegment(value: i, label: Text(labels[i])),
          ],
          selected: {index},
          onSelectionChanged: (s) => onChanged(s.first),
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
            foregroundColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            selectedBackgroundColor:
            AppColors.primary.withValues(alpha: 0.14),
            selectedForegroundColor: AppColors.primary,
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            textStyle: AppTextStyles.labelSmall
                .copyWith(fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Empty state
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isArabic,
    required this.isDark,
    required this.isSeller,
    required this.hasFilter,
  });
  final bool isArabic;
  final bool isDark;
  final bool isSeller;
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final icon = hasFilter
        ? Icons.filter_alt_off_outlined
        : (isSeller
        ? Icons.receipt_long_outlined
        : Icons.shopping_bag_outlined);

    final title = hasFilter
        ? (isArabic ? 'لا شيء في هذا الفلتر' : 'Nothing in this filter')
        : (isSeller
        ? (isArabic ? 'لا توجد طلبات واردة' : 'No incoming orders')
        : (isArabic ? 'لا مشتريات بعد' : 'No purchases yet'));

    final subtitle = hasFilter
        ? (isArabic
        ? 'جرّب فلتراً آخر أو اعرض الكل.'
        : 'Try another filter or view all.')
        : (isSeller
        ? (isArabic
        ? 'عندما يطلب طبيب أداة من أدواتك، ستظهر هنا.'
        : 'When a doctor requests one of your tools, it shows here.')
        : (isArabic
        ? 'تصفح السوق وقدّم طلب شراء.'
        : 'Browse the marketplace and request a purchase.'));

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
              child: Icon(icon, color: AppColors.primary, size: 56),
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
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 10),
            Text(
              subtitle,
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