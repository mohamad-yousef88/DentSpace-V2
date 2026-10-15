import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/tool.dart';
import '../bloc/tools_bloc.dart';
import '../bloc/tools_event.dart';
import '../bloc/tools_state.dart';
import '../widgets/tool_card.dart';

/// Doctor's own tool listings.
///
/// UX principles:
///   • Add button is prominent: extended FAB (no duplicate AppBar action).
///   • Status filter uses a Material 3 [SegmentedButton] — all options
///     visible inline, no scrolling, no tabs to swipe.
///   • Delete action lives on the card itself (available tools only).
class MyToolsPage extends StatefulWidget {
  const MyToolsPage({super.key});

  @override
  State<MyToolsPage> createState() => _MyToolsPageState();
}

class _MyToolsPageState extends State<MyToolsPage> {
  late final ToolsBloc _bloc;

  /// 0 = All · 1 = Available · 2 = Reserved · 3 = Sold
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<ToolsBloc>();
    _bloc.add(const LoadMyToolsEvent());
  }

  ToolStatus? get _activeFilter {
    switch (_filterIndex) {
      case 1:
        return ToolStatus.available;
      case 2:
        return ToolStatus.reserved;
      case 3:
        return ToolStatus.sold;
      default:
        return null;
    }
  }

  List<Tool> _filtered(List<Tool> all) {
    final filter = _activeFilter;
    if (filter == null) return all;
    return all.where((t) => t.status == filter).toList();
  }

  Future<void> _openDetail(int id) async {
    final changed = await context.push<bool>(Routes.toolDetails(id));
    if (changed == true && mounted) {
      _bloc.add(const LoadMyToolsEvent());
    }
  }

  Future<void> _openCreate() async {
    final created = await context.push<bool>(Routes.toolNew);
    if (created == true && mounted) {
      _bloc.add(const LoadMyToolsEvent());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Delete tool — confirm then dispatch
  // ═══════════════════════════════════════════════════════════════
  Future<void> _confirmDelete(Tool tool) async {
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(
          isArabic ? 'حذف الأداة' : 'Delete tool',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          isArabic
              ? 'سيتم حذف الأداة وصورها نهائياً. لا يمكن التراجع عن هذا الإجراء.'
              : 'The tool and its images will be permanently deleted. This cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'رجوع' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      _bloc.add(DeleteToolEvent(tool.id));
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
            isArabic ? 'أدواتي' : 'My Tools',
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // ─── Segmented filter bar ─────────────────────
            _SegmentedBar(
              index: _filterIndex,
              isArabic: isArabic,
              isDark: isDark,
              onChanged: (i) => setState(() => _filterIndex = i),
            ),

            // ─── List ─────────────────────────────────────
            Expanded(
              child: BlocConsumer<ToolsBloc, ToolsState>(
                listenWhen: (p, c) =>
                p.successMessage != c.successMessage ||
                    p.errorMessage != c.errorMessage,
                listener: (context, state) {
                  // ★ Handle deletion success.
                  if (state.successMessage == 'tool_deleted') {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text(
                          isArabic ? 'تم حذف الأداة' : 'Tool deleted',
                        ),
                        backgroundColor: AppColors.success,
                      ),);
                    _bloc.add(const ClearToolFeedbackEvent());
                    _bloc.add(const LoadMyToolsEvent());
                    return;
                  }

                  // Any other mutation success (edit updates).
                  if (state.successMessage == 'tool_updated') {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text(
                          isArabic ? 'تم تحديث الأداة' : 'Tool updated',
                        ),
                        backgroundColor: AppColors.success,
                      ),);
                    _bloc.add(const ClearToolFeedbackEvent());
                    _bloc.add(const LoadMyToolsEvent());
                    return;
                  }

                  if (state.errorMessage != null &&
                      state.status == ToolsStatus.failure) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text(state.errorMessage!),
                        backgroundColor: AppColors.error,
                      ),);
                    _bloc.add(const ClearToolFeedbackEvent());
                  }
                },
                builder: (context, state) {
                  if (state.isLoading && state.tools.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  final items = _filtered(state.tools);

                  if (items.isEmpty) {
                    return _EmptyState(
                      isArabic: isArabic,
                      isDark: isDark,
                      hasAnyTools: state.tools.isNotEmpty,
                      onCreate: _openCreate,
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      _bloc.add(const LoadMyToolsEvent());
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final t = items[i];
                        // ★ Delete visible only for editable (available) tools.
                        final canDelete = t.status.isEditable;

                        return ToolCard(
                          tool: t,
                          showStatusBadge: true,
                          onTap: () => _openDetail(t.id),
                          onDelete:
                          canDelete ? () => _confirmDelete(t) : null,
                        )
                            .animate(delay: (i * 50).ms)
                            .fadeIn(duration: 300.ms);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: _openCreate,
          icon: const Icon(Icons.add_rounded),
          label: Text(isArabic ? 'أداة جديدة' : 'New tool'),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Segmented filter bar (Material 3)
// ═══════════════════════════════════════════════════════════════
class _SegmentedBar extends StatelessWidget {
  const _SegmentedBar({
    required this.index,
    required this.isArabic,
    required this.isDark,
    required this.onChanged,
  });
  final int index;
  final bool isArabic;
  final bool isDark;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 0,
              label: Text(isArabic ? 'الكل' : 'All'),
            ),
            ButtonSegment(
              value: 1,
              label: Text(isArabic ? 'متاح' : 'Available'),
            ),
            ButtonSegment(
              value: 2,
              label: Text(isArabic ? 'محجوز' : 'Reserved'),
            ),
            ButtonSegment(
              value: 3,
              label: Text(isArabic ? 'مبيع' : 'Sold'),
            ),
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
            textStyle: AppTextStyles.labelMedium
                .copyWith(fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Empty state (two variants)
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isArabic,
    required this.isDark,
    required this.hasAnyTools,
    required this.onCreate,
  });

  final bool isArabic;
  final bool isDark;

  /// `true` → the doctor has tools, just none in the selected filter.
  final bool hasAnyTools;

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    if (hasAnyTools) {
      // Filter yielded nothing — smaller, actionable message.
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.filter_alt_off_outlined,
                size: 56,
                color: AppColors.primary,
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
              Text(
                isArabic ? 'لا شيء في هذا التصنيف' : 'Nothing in this filter',
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isArabic
                    ? 'جرّب تصنيفاً آخر أو اعرض الكل.'
                    : 'Try another filter or view all.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No tools at all — prominent CTA.
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
                Icons.inventory_2_outlined,
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
              isArabic ? 'لا توجد أدوات بعد' : 'No tools yet',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 10),
            Text(
              isArabic
                  ? 'ابدأ بعرض أول أداة للبيع على المنصة.'
                  : 'List your first tool on the marketplace.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.5,
              ),
            ).animate(delay: 350.ms).fadeIn(),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                isArabic ? 'إضافة أول أداة' : 'Add your first tool',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ).animate(delay: 500.ms).fadeIn().slideY(
              begin: 0.2,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}