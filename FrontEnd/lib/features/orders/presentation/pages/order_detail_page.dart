import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/order.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';

/// Full order detail with a lifecycle timeline and role-aware actions.
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final int orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final OrdersBloc _bloc;
  bool _wasMutated = false;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<OrdersBloc>();
    _bloc.add(LoadOrderByIdEvent(widget.orderId));
  }

  bool get _isSeller {
    final me = GetIt.instance<AuthBloc>().state.user;
    final order = _bloc.state.currentOrder;
    return me != null && order != null && me.id == order.seller?.id;
  }

  // ═══════════════════════════════════════════════════════════════
  Future<void> _confirm({
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
    required String actionAr,
    required String actionEn,
    required Color actionColor,
    required VoidCallback onConfirm,
  }) async {
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await showDialog<bool>(
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
    if (ok == true) onConfirm();
  }

  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<OrdersBloc, OrdersState>(
        listenWhen: (p, c) =>
        p.successMessage != c.successMessage ||
            p.errorMessage != c.errorMessage,
        listener: (context, state) {
          if (state.successMessage != null) {
            _wasMutated = true;
            final map = {
              'order_approved': isArabic ? 'تم قبول الطلب' : 'Order approved',
              'order_rejected': isArabic ? 'تم رفض الطلب' : 'Order rejected',
              'order_completed':
              isArabic ? 'تم تأكيد البيع' : 'Order completed',
              'order_cancelled':
              isArabic ? 'تم إلغاء الطلب' : 'Order cancelled',
            };
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(map[state.successMessage] ?? 'OK'),
                backgroundColor: AppColors.success,
              ),);
            _bloc.add(const ClearOrderFeedbackEvent());
            _bloc.add(LoadOrderByIdEvent(widget.orderId));
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
          final order = state.currentOrder;

          return Scaffold(
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
                onPressed: () => context.pop(_wasMutated),
              ),
              title: Text(
                isArabic ? 'تفاصيل الطلب' : 'Order details',
                style: AppTextStyles.titleLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
            ),
            body: order == null
                ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
                : _buildBody(order, isArabic, isDark, state.isSubmitting),
            bottomNavigationBar: order == null
                ? null
                : _buildBottomBar(order, isArabic, isDark, state.isSubmitting),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  Widget _buildBody(
      Order order,
      bool isArabic,
      bool isDark,
      bool isSubmitting,
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusHeader(order: order, isArabic: isArabic, isDark: isDark),
          const SizedBox(height: 18),
          if (order.tool != null)
            _ToolCard(tool: order.tool!, isArabic: isArabic, isDark: isDark),
          if (order.buyer != null) ...[
            const SizedBox(height: 14),
            _PartyCard(
              label: isArabic ? 'المشتري' : 'Buyer',
              user: order.buyer!,
              icon: Icons.person_outline_rounded,
              color: AppColors.primary,
              isDark: isDark,
            ),
          ],
          if (order.seller != null) ...[
            const SizedBox(height: 14),
            _PartyCard(
              label: isArabic ? 'البائع' : 'Seller',
              user: order.seller!,
              icon: Icons.storefront_outlined,
              color: AppColors.secondary,
              isDark: isDark,
            ),
          ],
          if (order.message != null && order.message!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _MessageCard(
              message: order.message!,
              isArabic: isArabic,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 18),
          _Timeline(order: order, isArabic: isArabic, isDark: isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  Widget _buildBottomBar(
      Order order,
      bool isArabic,
      bool isDark,
      bool isSubmitting,
      ) {
    final isSeller = _isSeller;
    final buttons = <Widget>[];

    if (isSeller && order.status.isPending) {
      buttons.add(_outlined(
        label: isArabic ? 'رفض' : 'Reject',
        icon: Icons.close_rounded,
        color: AppColors.error,
        enabled: !isSubmitting,
        onPressed: () => _confirm(
          titleAr: 'رفض الطلب',
          titleEn: 'Reject order',
          bodyAr: 'هل تريد رفض هذا الطلب؟',
          bodyEn: 'Reject this order?',
          actionAr: 'رفض',
          actionEn: 'Reject',
          actionColor: AppColors.error,
          onConfirm: () => _bloc.add(RejectOrderEvent(order.id)),
        ),
      ),);
      buttons.add(_filled(
        label: isArabic ? 'قبول' : 'Approve',
        icon: Icons.check_rounded,
        color: AppColors.success,
        enabled: !isSubmitting,
        onPressed: () => _confirm(
          titleAr: 'قبول الطلب',
          titleEn: 'Approve order',
          bodyAr: 'سيتم حجز الأداة لهذا المشتري.',
          bodyEn: 'The tool will be reserved for this buyer.',
          actionAr: 'قبول',
          actionEn: 'Approve',
          actionColor: AppColors.success,
          onConfirm: () => _bloc.add(ApproveOrderEvent(order.id)),
        ),
      ),);
    } else if (isSeller && order.status.isApproved) {
      buttons.add(_outlined(
        label: isArabic ? 'إلغاء' : 'Cancel',
        icon: Icons.cancel_outlined,
        color: AppColors.error,
        enabled: !isSubmitting,
        onPressed: () => _confirm(
          titleAr: 'إلغاء الطلب',
          titleEn: 'Cancel order',
          bodyAr: 'هل تريد إلغاء هذا الطلب؟',
          bodyEn: 'Cancel this order?',
          actionAr: 'إلغاء',
          actionEn: 'Cancel',
          actionColor: AppColors.error,
          onConfirm: () => _bloc.add(CancelOrderEvent(order.id)),
        ),
      ),);
      buttons.add(_filled(
        label: isArabic ? 'تأكيد البيع' : 'Mark sold',
        icon: Icons.task_alt_rounded,
        color: AppColors.success,
        enabled: !isSubmitting,
        onPressed: () => _confirm(
          titleAr: 'تأكيد البيع',
          titleEn: 'Mark as sold',
          bodyAr: 'سيتم تعليم الأداة كمبيعة نهائياً.',
          bodyEn: 'The tool will be marked as sold.',
          actionAr: 'تأكيد',
          actionEn: 'Confirm',
          actionColor: AppColors.success,
          onConfirm: () => _bloc.add(CompleteOrderEvent(order.id)),
        ),
      ),);
    } else if (!isSeller && order.status.isActive) {
      buttons.add(_outlined(
        label: isArabic ? 'إلغاء الطلب' : 'Cancel request',
        icon: Icons.cancel_outlined,
        color: AppColors.error,
        enabled: !isSubmitting,
        onPressed: () => _confirm(
          titleAr: 'إلغاء الطلب',
          titleEn: 'Cancel request',
          bodyAr: 'هل تريد إلغاء طلب الشراء؟',
          bodyEn: 'Cancel this purchase request?',
          actionAr: 'إلغاء',
          actionEn: 'Cancel',
          actionColor: AppColors.error,
          onConfirm: () => _bloc.add(CancelOrderEvent(order.id)),
        ),
      ),);
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (var i = 0; i < buttons.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 10));
      children.add(Expanded(child: buttons[i]));
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(children: children),
        ),
      ),
    );
  }

  Widget _outlined({
    required String label,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onPressed,
  }) =>
      OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

  Widget _filled({
    required String label,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onPressed,
  }) =>
      FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// Status header
// ═══════════════════════════════════════════════════════════════
class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.order,
    required this.isArabic,
    required this.isDark,
  });
  final Order order;
  final bool isArabic;
  final bool isDark;

  String _label() {
    switch (order.status) {
      case OrderStatus.pending:
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case OrderStatus.approved:
        return isArabic ? 'معتمد' : 'Approved';
      case OrderStatus.rejected:
        return isArabic ? 'مرفوض' : 'Rejected';
      case OrderStatus.cancelled:
        return isArabic ? 'ملغى' : 'Cancelled';
      case OrderStatus.completed:
        return isArabic ? 'مكتمل' : 'Completed';
    }
  }

  Color _color() {
    switch (order.status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.approved:
        return AppColors.success;
      case OrderStatus.rejected:
        return AppColors.error;
      case OrderStatus.cancelled:
        return AppColors.warning;
      case OrderStatus.completed:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.20 : 0.10),
            color.withValues(alpha: isDark ? 0.08 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              order.status.isPending
                  ? Icons.hourglass_empty_rounded
                  : order.status.isApproved
                  ? Icons.check_circle_rounded
                  : order.status.isCompleted
                  ? Icons.verified_rounded
                  : order.status.isRejected
                  ? Icons.cancel_rounded
                  : Icons.event_busy_rounded,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'حالة الطلب' : 'Order status',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _label(),
                  style: AppTextStyles.titleLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '#${order.id}',
            style: AppTextStyles.labelMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ═══════════════════════════════════════════════════════════════
// Tool card
// ═══════════════════════════════════════════════════════════════
class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.tool,
    required this.isArabic,
    required this.isDark,
  });
  final OrderToolBrief tool;
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final image = tool.imageUrls.isNotEmpty ? tool.imageUrls.first : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: image == null
                  ? Container(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
                alignment: Alignment.center,
                child: Icon(
                  Icons.handyman_outlined,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              )
                  : CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${tool.price.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 80.ms).fadeIn(duration: 350.ms);
  }
}

// ═══════════════════════════════════════════════════════════════
// Party card
// ═══════════════════════════════════════════════════════════════
class _PartyCard extends StatelessWidget {
  const _PartyCard({
    required this.label,
    required this.user,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String label;
  final OrderUserBrief user;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final initial = user.fullName.trim().isEmpty
        ? '?'
        : user.fullName.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.phone,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 140.ms).fadeIn(duration: 350.ms);
  }
}

// ═══════════════════════════════════════════════════════════════
// Message card
// ═══════════════════════════════════════════════════════════════
class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.isArabic,
    required this.isDark,
  });
  final String message;
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'رسالة المشتري' : 'Buyer message',
                style: AppTextStyles.titleSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 350.ms);
  }
}

// ═══════════════════════════════════════════════════════════════
// Timeline
// ═══════════════════════════════════════════════════════════════
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.order,
    required this.isArabic,
    required this.isDark,
  });
  final Order order;
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final steps = <_Step>[
      _Step(
        icon: Icons.shopping_bag_outlined,
        label: isArabic ? 'تم إنشاء الطلب' : 'Order created',
        time: order.createdAt,
        done: true,
      ),
      _Step(
        icon: order.status.isRejected
            ? Icons.cancel_rounded
            : Icons.check_circle_rounded,
        label: order.status.isRejected
            ? (isArabic ? 'تم الرفض' : 'Rejected')
            : (isArabic ? 'تم القبول' : 'Approved'),
        time: order.respondedAt,
        done: order.status.isApproved ||
            order.status.isCompleted ||
            order.status.isRejected,
        color: order.status.isRejected ? AppColors.error : AppColors.success,
      ),
      if (!order.status.isRejected && !order.status.isCancelled)
        _Step(
          icon: Icons.verified_rounded,
          label: isArabic ? 'تم البيع' : 'Sold',
          time: order.status.isCompleted ? order.respondedAt : null,
          done: order.status.isCompleted,
          color: AppColors.info,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timeline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'سجل الطلب' : 'Order timeline',
                style: AppTextStyles.titleSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final isLast = i == steps.length - 1;
            return _TimelineRow(
              step: s,
              isLast: isLast,
              isArabic: isArabic,
              isDark: isDark,
            );
          }),
        ],
      ),
    ).animate(delay: 260.ms).fadeIn(duration: 350.ms);
  }
}

class _Step {
  const _Step({
    required this.icon,
    required this.label,
    required this.done,
    this.time,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool done;
  final DateTime? time;
  final Color? color;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isLast,
    required this.isArabic,
    required this.isDark,
  });
  final _Step step;
  final bool isLast;
  final bool isArabic;
  final bool isDark;

  String _fmtDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d · $h:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final color = step.done
        ? (step.color ?? AppColors.primary)
        : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: step.done ? 0.18 : 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(step.icon, size: 15, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    step.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: step.done
                          ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                          : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                      fontWeight:
                      step.done ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (step.time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _fmtDate(step.time!),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}