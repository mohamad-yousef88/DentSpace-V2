import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.isSellerView,
    required this.onTap,
    required this.isSubmitting,
    this.onApprove,
    this.onReject,
    this.onComplete,
    this.onCancel,
    this.onHide,
    this.restoreMode = false,
  });

  final Order order;
  final bool isSellerView;
  final VoidCallback onTap;
  final bool isSubmitting;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  /// Available only for terminal orders (completed / rejected / cancelled).
  final VoidCallback? onHide;

  /// When `true`, the trailing icon becomes "Restore" (undo arrow).
  /// Used by the Hidden History screen.
  final bool restoreMode;

  // ─── Status helpers ────────────────────────────────────
  String _statusLabel(bool isArabic) {
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

  Color _statusColor() {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';

    final tool = order.tool;
    final otherParty = isSellerView ? order.buyer : order.seller;
    final otherLabel = isSellerView
        ? (isArabic ? 'المشتري' : 'Buyer')
        : (isArabic ? 'البائع' : 'Seller');
    final statusColor = _statusColor();

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ─────────────────────────────
              Row(
                children: [
                  _Thumbnail(
                    url: tool?.imageUrls.isNotEmpty == true
                        ? tool!.imageUrls.first
                        : null,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool?.name ?? (isArabic ? 'أداة' : 'Tool'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isDark
                                ? Colors.white
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${(tool?.price ?? 0).toStringAsFixed(2)}',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(isArabic),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // ★ Trailing icon — restore (in hidden mode) or hide
                  if (onHide != null) ...[
                    const SizedBox(width: 4),
                    _IconAction(
                      icon: restoreMode
                          ? Icons.restore_rounded
                          : Icons.delete_outline_rounded,
                      color:
                      restoreMode ? AppColors.primary : AppColors.error,
                      tooltip: restoreMode
                          ? (isArabic ? 'استعادة' : 'Restore')
                          : (isArabic ? 'إخفاء من القائمة' : 'Hide'),
                      onTap: onHide!,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // ─── Other party ────────────────────────
              if (otherParty != null)
                Row(
                  children: [
                    Icon(
                      isSellerView
                          ? Icons.person_outline_rounded
                          : Icons.storefront_outlined,
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$otherLabel: ${otherParty.fullName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

              // ─── Message ────────────────────────────
              if (order.message != null && order.message!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order.message!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],

              _buildActions(context, isArabic),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isArabic) {
    final buttons = <Widget>[];

    if (onReject != null) {
      buttons.add(_outlined(
        label: isArabic ? 'رفض' : 'Reject',
        icon: Icons.close_rounded,
        color: AppColors.error,
        onPressed: onReject!,
      ),);
    }
    if (onApprove != null) {
      buttons.add(_filled(
        label: isArabic ? 'قبول' : 'Approve',
        icon: Icons.check_rounded,
        color: AppColors.success,
        onPressed: onApprove!,
      ),);
    }
    if (onCancel != null) {
      buttons.add(_outlined(
        label: isArabic ? 'إلغاء' : 'Cancel',
        icon: Icons.cancel_outlined,
        color: AppColors.error,
        onPressed: onCancel!,
      ),);
    }
    if (onComplete != null) {
      buttons.add(_filled(
        label: isArabic ? 'تأكيد البيع' : 'Mark sold',
        icon: Icons.task_alt_rounded,
        color: AppColors.success,
        onPressed: onComplete!,
      ),);
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (var i = 0; i < buttons.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 8));
      children.add(Expanded(child: buttons[i]));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: children),
    );
  }

  Widget _outlined({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: isSubmitting ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size.fromHeight(42),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }

  Widget _filled({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return FilledButton.icon(
      onPressed: isSubmitting ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size.fromHeight(42),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.isDark});
  final String? url;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: url == null
            ? _placeholder()
            : CachedNetworkImage(
          imageUrl: url!,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant,
    alignment: Alignment.center,
    child: Icon(
      Icons.handyman_outlined,
      size: 24,
      color: isDark
          ? AppColors.darkTextTertiary
          : AppColors.lightTextTertiary,
    ),
  );
}