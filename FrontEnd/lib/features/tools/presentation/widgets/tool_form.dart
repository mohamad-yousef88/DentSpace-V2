import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/tool_catalogue.dart';

class ToolForm extends StatelessWidget {
  const ToolForm({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.descCtrl,
    required this.priceCtrl,
    required this.category,
    required this.condition,
    required this.onCategoryChanged,
    required this.onConditionChanged,
    required this.imagePaths,
    required this.onAddImages,
    required this.onRemoveImage,
    required this.isSubmitting,
    this.existingImages = const [],
    this.onRemoveExistingImage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController priceCtrl;
  final String? category;
  final String? condition;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onConditionChanged;
  final List<String> imagePaths;
  final VoidCallback onAddImages;
  final ValueChanged<int> onRemoveImage;
  final List<String> existingImages;
  final ValueChanged<int>? onRemoveExistingImage;
  final bool isSubmitting;

  static const int _maxImages = 5;

  int get _totalImages => existingImages.length + imagePaths.length;


  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // ─── Images ───────────────────────────────
          _SectionLabel(
            isArabic: isArabic,
            labelAr: 'صور الأداة',
            labelEn: 'Tool images',
            hint: '$_totalImages / $_maxImages',
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'حتى 5 صور. اضغط على الصورة لحذفها.'
                : 'Up to 5 images. Tap an image to remove it.',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 12),
          _ImageSlots(
            existingImages: existingImages,
            newPaths: imagePaths,
            maxImages: _maxImages,
            enabled: !isSubmitting,
            onAdd: onAddImages,
            onRemoveNew: onRemoveImage,
            onRemoveExisting: onRemoveExistingImage,
          ),
          const SizedBox(height: 24),

          // ─── Name ────────────────────────────────
          TextFormField(
            controller: nameCtrl,
            enabled: !isSubmitting,
            textInputAction: TextInputAction.next,
            maxLength: 150,
            decoration: InputDecoration(
              labelText: isArabic ? 'اسم الأداة' : 'Tool name',
              prefixIcon: const Icon(Icons.handyman_outlined),
              counterText: '',
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.length < 2) {
                return isArabic
                    ? 'على الأقل حرفان'
                    : 'At least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // ─── Category ─────────────────────────────
          _PickerField(
            label: isArabic ? 'التصنيف' : 'Category',
            valueLabel: category == null
                ? null
                : (toolCategoryByKey(category!)
                ?.labelFor(isArabic: isArabic) ??
                category!),
            icon: Icons.category_outlined,
            enabled: !isSubmitting,
            onTap: () => _showCategoryPicker(context, isArabic),
          ),
          const SizedBox(height: 14),

          // ─── Condition ────────────────────────────
          _PickerField(
            label: isArabic ? 'الحالة' : 'Condition',
            valueLabel: condition == null
                ? null
                : (toolConditionByKey(condition!)
                ?.labelFor(isArabic: isArabic) ??
                condition!),
            icon: Icons.star_border_rounded,
            enabled: !isSubmitting,
            onTap: () => _showConditionPicker(context, isArabic),
          ),
          const SizedBox(height: 14),

          // ─── Price ────────────────────────────────
          TextFormField(
            controller: priceCtrl,
            enabled: !isSubmitting,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: isArabic ? 'السعر (\$)' : 'Price (\$)',
              prefixIcon: const Icon(Icons.attach_money_rounded),
            ),
            validator: (v) {
              final value = double.tryParse(v?.trim() ?? '');
              if (value == null || value <= 0) {
                return isArabic
                    ? 'أدخل سعراً صحيحاً'
                    : 'Enter a valid price';
              }
              if (value > 1000000) {
                return isArabic ? 'السعر مرتفع جداً' : 'Price too high';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // ─── Description ──────────────────────────
          TextFormField(
            controller: descCtrl,
            enabled: !isSubmitting,
            maxLines: 5,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: isArabic ? 'الوصف' : 'Description',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 80),
                child: Icon(Icons.description_outlined),
              ),
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.length < 5) {
                return isArabic
                    ? 'على الأقل 5 أحرف'
                    : 'At least 5 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  Future<void> _showCategoryPicker(
      BuildContext context,
      bool isArabic,
      ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: isArabic ? 'اختر التصنيف' : 'Choose category',
        options: kToolCategories
            .map((c) => _PickerOption(
          key: c.key,
          label: c.labelFor(isArabic: isArabic),
          icon: c.icon,
        ),)
            .toList(),
        current: category,
      ),
    );
    if (selected != null) onCategoryChanged(selected);
  }

  Future<void> _showConditionPicker(
      BuildContext context,
      bool isArabic,
      ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: isArabic ? 'اختر الحالة' : 'Choose condition',
        options: kToolConditions
            .map((c) => _PickerOption(
          key: c.key,
          label: c.labelFor(isArabic: isArabic),
          icon: Icons.check_circle_outline_rounded,
        ),)
            .toList(),
        current: condition,
      ),
    );
    if (selected != null) onConditionChanged(selected);
  }
}

// ═══════════════════════════════════════════════════════════════
// Section label
// ═══════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.isArabic,
    required this.labelAr,
    required this.labelEn,
    this.hint,
  });
  final bool isArabic;
  final String labelAr;
  final String labelEn;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          isArabic ? labelAr : labelEn,
          style: AppTextStyles.titleSmall.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (hint != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hint!,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Image slots — organised grid
// ═══════════════════════════════════════════════════════════════
class _ImageSlots extends StatelessWidget {
  const _ImageSlots({
    required this.existingImages,
    required this.newPaths,
    required this.maxImages,
    required this.enabled,
    required this.onAdd,
    required this.onRemoveNew,
    this.onRemoveExisting,
  });

  final List<String> existingImages;
  final List<String> newPaths;
  final int maxImages;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveNew;
  final ValueChanged<int>? onRemoveExisting;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build a list of tiles: filled slots + empty add slot if room.
    final tiles = <Widget>[];
    for (var i = 0; i < existingImages.length; i++) {
      tiles.add(_ImageTile(
        isDark: isDark,
        onRemove: enabled && onRemoveExisting != null
            ? () => onRemoveExisting!(i)
            : null,
        child: Image.network(
          existingImages[i],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _brokenImage(isDark),
        ),
      ),);
    }
    for (var i = 0; i < newPaths.length; i++) {
      tiles.add(_ImageTile(
        isDark: isDark,
        onRemove: enabled ? () => onRemoveNew(i) : null,
        child: Image.file(File(newPaths[i]), fit: BoxFit.cover),
      ),);
    }
    if (tiles.length < maxImages) {
      tiles.add(_AddTile(
        isDark: isDark,
        enabled: enabled,
        onTap: onAdd,
      ),);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute tile size: 4 columns if wide enough, else 3.
        const spacing = 10.0;
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 380 ? 4 : 3;
        final tileSize =
            (maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map((t) => SizedBox(
            width: tileSize,
            height: tileSize,
            child: t,
          ),)
              .toList(),
        );
      },
    );
  }

  Widget _brokenImage(bool isDark) => ColoredBox(
    color: isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant,
    child: Icon(
      Icons.broken_image_outlined,
      color: isDark
          ? AppColors.darkTextTertiary
          : AppColors.lightTextTertiary,
    ),
  );
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.isDark,
    required this.child,
    this.onRemove,
  });
  final bool isDark;
  final Widget child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (onRemove != null)
            PositionedDirectional(
              top: 4,
              end: 4,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.isDark,
    required this.enabled,
    required this.onTap,
  });
  final bool isDark;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightSurfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.primary.withValues(alpha: 0.7),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                '+',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
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
// Picker field
// ═══════════════════════════════════════════════════════════════
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.valueLabel,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final String? valueLabel;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightSurfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    valueLabel ?? label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: valueLabel == null
                          ? (isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary)
                          : (isDark
                          ? Colors.white
                          : AppColors.lightTextPrimary),
                      fontWeight: valueLabel == null
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Picker sheet
// ═══════════════════════════════════════════════════════════════
class _PickerOption {
  const _PickerOption({
    required this.key,
    required this.label,
    required this.icon,
  });
  final String key;
  final String label;
  final IconData icon;
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.current,
  });
  final String title;
  final List<_PickerOption> options;
  final String? current;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              ...options.map((o) {
                final selected = current == o.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context, o.key),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              o.icon,
                              size: 20,
                              color: selected
                                  ? AppColors.primary
                                  : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                o.label,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: selected
                                      ? AppColors.primary
                                      : (isDark
                                      ? Colors.white
                                      : AppColors.lightTextPrimary),
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}