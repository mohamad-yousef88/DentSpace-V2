import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/order.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';
import '../widgets/order_card.dart';

/// Hidden History screen — displays every order the user has hidden
/// from either their seller or buyer view, with per-item restore.
///
/// The underlying order is **never deleted on the backend** — this
/// screen only surfaces and manages the local hide list.
class HiddenOrdersPage extends StatefulWidget {
  const HiddenOrdersPage({super.key});

  @override
  State<HiddenOrdersPage> createState() => _HiddenOrdersPageState();
}

class _HiddenOrdersPageState extends State<HiddenOrdersPage> {
  late final OrdersBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<OrdersBloc>();
    _bloc.add(const LoadHiddenOrdersEvent());
  }

  // ═══════════════════════════════════════════════════════════════
  Future<void> _restore(Order o) async {
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';

    _bloc.add(UnhideOrderEvent(o.id));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          isArabic ? 'تم استعادة الطلب' : 'Order restored',
        ),
        backgroundColor: AppColors.success,
      ),);
  }

  Future<void> _confirmRestoreAll() async {
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(
          isArabic ? 'استعادة الكل' : 'Restore all',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          isArabic
              ? 'سيتم إرجاع جميع الطلبات المخفية إلى قوائمها الأصلية.'
              : 'All hidden orders will reappear in their original lists.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'رجوع' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isArabic ? 'استعادة الكل' : 'Restore all'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // Restore every visible item, one after another.
    final items = _bloc.state.orders;
    for (final o in items) {
      _bloc.add(UnhideOrderEvent(o.id));
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
            isArabic ? 'السجل المخفي' : 'Hidden History',
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            BlocBuilder<OrdersBloc, OrdersState>(
              builder: (context, state) {
                if (state.orders.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  tooltip: isArabic ? 'استعادة الكل' : 'Restore all',
                  icon: const Icon(Icons.restore_rounded),
                  onPressed: _confirmRestoreAll,
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<OrdersBloc, OrdersState>(
          listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage ||
              p.successMessage != c.successMessage,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                ),);
              _bloc.add(const ClearOrderFeedbackEvent());
            }
            if (state.successMessage != null) {
              _bloc.add(const ClearOrderFeedbackEvent());
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.orders.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state.orders.isEmpty) {
              return _EmptyState(isArabic: isArabic, isDark: isDark);
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async =>
                  _bloc.add(const LoadHiddenOrdersEvent()),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: state.orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final o = state.orders[i];
                  return OrderCard(
                    key: ValueKey(o.id),
                    order: o,
                    isSellerView: true, // display-only, both roles look same
                    isSubmitting: state.isSubmitting,
                    restoreMode: true,
                    onTap: () {}, // no navigation from hidden list
                    onHide: () => _restore(o),
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
    );
  }
}

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
                Icons.restore_from_trash_outlined,
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
              isArabic ? 'لا توجد طلبات مخفية' : 'No hidden orders',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 10),
            Text(
              isArabic
                  ? 'عندما تُخفي طلباً من قائمة الطلبات، سيظهر هنا ويمكنك استعادته.'
                  : 'When you hide an order from the Orders list, it will appear here and can be restored.',
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