import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/tool_catalogue.dart';
import '../../domain/entities/tool.dart';

class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.tool,
    required this.onTap,
    this.showStatusBadge = false,
    this.onDelete,
  });

  final Tool tool;
  final VoidCallback onTap;
  final bool showStatusBadge;

  /// When non-null, a delete icon appears in the header.
  /// Only wired up by [MyToolsPage] — for `available` tools only.
  final VoidCallback? onDelete;

  // ─── Status helpers ─────────────────────────────────────
  String _statusLabel(bool isArabic) {
    switch (tool.status) {
      case ToolStatus.available:
        return isArabic ? 'متاح' : 'Available';
      case ToolStatus.reserved:
        return isArabic ? 'محجوز' : 'Reserved';
      case ToolStatus.sold:
        return isArabic ? 'مبيع' : 'Sold';
      case ToolStatus.archived:
        return isArabic ? 'مؤرشف' : 'Archived';
    }
  }

  Color _statusColor() {
    switch (tool.status) {
      case ToolStatus.available:
        return AppColors.success;
      case ToolStatus.reserved:
        return AppColors.warning;
      case ToolStatus.sold:
        return AppColors.info;
      case ToolStatus.archived:
        return AppColors.lightTextTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(tool: tool, isDark: isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Name + status + delete ──────
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tool.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (showStatusBadge) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                              _statusColor().withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(isArabic),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _statusColor(),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (onDelete != null) ...[
                          const SizedBox(width: 2),
                          _IconAction(
                            icon: Icons.delete_outline_rounded,
                            color: AppColors.error,
                            tooltip:
                            isArabic ? 'حذف الأداة' : 'Delete tool',
                            onTap: onDelete!,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Pill(
                          label: translateToolCategory(
                            tool.category,
                            isArabic: isArabic,
                          ),
                          color: AppColors.primary,
                        ),
                        _Pill(
                          label: translateToolCondition(
                            tool.condition,
                            isArabic: isArabic,
                          ),
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${tool.price.toStringAsFixed(2)}',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
  const _Thumbnail({required this.tool, required this.isDark});
  final Tool tool;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 90,
        height: 90,
        child: tool.hasImages
            ? CachedNetworkImage(
          imageUrl: tool.primaryImage,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.lightSurfaceVariant,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => _placeholder(isDark),
        )
            : _placeholder(isDark),
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      color: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightSurfaceVariant,
      alignment: Alignment.center,
      child: Icon(
        Icons.handyman_outlined,
        color: isDark
            ? AppColors.darkTextTertiary
            : AppColors.lightTextTertiary,
        size: 32,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
  });
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}