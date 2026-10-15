import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/helpers/debouncer.dart';
import '../../data/tool_catalogue.dart';
import '../bloc/tools_bloc.dart';
import '../bloc/tools_event.dart';
import '../bloc/tools_state.dart';
import '../widgets/tool_card.dart';

class ToolsMarketPage extends StatefulWidget {
  const ToolsMarketPage({super.key});

  @override
  State<ToolsMarketPage> createState() => _ToolsMarketPageState();
}

class _ToolsMarketPageState extends State<ToolsMarketPage> {
  late final ToolsBloc _bloc;
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 400));

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<ToolsBloc>();
    _bloc.add(const LoadMarketToolsEvent());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  void _onSearchChanged() {
    setState(() {});
    _debouncer.run(_reload);
  }

  void _reload() {
    _bloc.add(LoadMarketToolsEvent(
      search: _searchController.text.trim(),
      category: _selectedCategory,
    ),);
  }

  Future<void> _openFilter() async {
    final result = await showModalBottomSheet<_CategoryFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFilterSheet(current: _selectedCategory),
    );
    if (result == null || !mounted) return;
    setState(() => _selectedCategory = result.category);
    _reload();
  }

  void _clearCategory() {
    setState(() => _selectedCategory = null);
    _reload();
  }

  Future<void> _openDetail(int id) async {
    final changed = await context.push<bool>(Routes.toolDetails(id));
    if (changed == true && mounted) _reload();
  }

  Future<void> _openMyTools() async {
    final changed = await context.push<bool>(Routes.myTools);
    if (changed == true && mounted) _reload();
  }

  // ★ FIX #2 — الزر ينقل لصفحة الإنشاء فعلاً
  Future<void> _openCreateTool() async {
    final created = await context.push<bool>(Routes.toolNew);
    if (created == true && mounted) _reload();
  }

  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFilter = _selectedCategory != null;

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
            isArabic ? 'سوق الأدوات' : 'Tools Market',
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: isArabic ? 'أدواتي' : 'My tools',
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: _openMyTools,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: IconButton(
                tooltip: isArabic ? 'تصفية' : 'Filter',
                onPressed: _openFilter,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.tune_rounded),
                    if (hasFilter)
                      PositionedDirectional(
                        end: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _SearchBar(
              controller: _searchController,
              isArabic: isArabic,
              isDark: isDark,
            ),
            if (hasFilter)
              _ActiveFilterBar(
                label: translateToolCategory(
                  _selectedCategory!,
                  isArabic: isArabic,
                ),
                isArabic: isArabic,
                isDark: isDark,
                onClear: _clearCategory,
              )
                  .animate()
                  .fadeIn(duration: 250.ms)
                  .slideY(begin: -0.2, end: 0, duration: 250.ms),
            Expanded(
              child: BlocConsumer<ToolsBloc, ToolsState>(
                listener: (context, state) {
                  if (state.errorMessage != null &&
                      state.status == ToolsStatus.failure) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text(state.errorMessage!),
                        backgroundColor: AppColors.error,
                      ),);
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
                  if (state.tools.isEmpty) {
                    return _EmptyState(
                      isArabic: isArabic,
                      isDark: isDark,
                      hasFilters:
                      _searchController.text.trim().isNotEmpty ||
                          _selectedCategory != null,
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => _reload(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: state.tools.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final t = state.tools[i];
                        return ToolCard(
                          tool: t,
                          onTap: () => _openDetail(t.id),
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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: _openCreateTool,
          icon: const Icon(Icons.add_rounded),
          label: Text(isArabic ? 'أداة جديدة' : 'New tool'),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Search bar
// ═══════════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isArabic,
    required this.isDark,
  });
  final TextEditingController controller;
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? Colors.white : AppColors.lightTextPrimary,
        ),
        decoration: InputDecoration(
          hintText:
          isArabic ? 'ابحث عن أداة بالاسم...' : 'Search by tool name...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: controller.clear,
          ),
          filled: true,
          fillColor: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Active filter bar
// ═══════════════════════════════════════════════════════════════
class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({
    required this.label,
    required this.isArabic,
    required this.isDark,
    required this.onClear,
  });
  final String label;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsetsDirectional.only(
              start: 12,
              end: 6,
              top: 6,
              bottom: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isArabic ? 'مسح' : 'Clear',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Category filter sheet
// ═══════════════════════════════════════════════════════════════
class _CategoryFilterResult {
  const _CategoryFilterResult(this.category);
  final String? category;
}

class _CategoryFilterSheet extends StatefulWidget {
  const _CategoryFilterSheet({this.current});
  final String? current;

  @override
  State<_CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<_CategoryFilterSheet> {
  String? _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
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
                isArabic ? 'تصفية حسب التصنيف' : 'Filter by category',
                style: AppTextStyles.titleLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.4,
                children: [
                  _CategoryTile(
                    label: isArabic ? 'الكل' : 'All',
                    icon: Icons.apps_rounded,
                    selected: _draft == null,
                    onTap: () => setState(() => _draft = null),
                    isDark: isDark,
                  ),
                  for (final c in kToolCategories)
                    _CategoryTile(
                      label: c.labelFor(isArabic: isArabic),
                      icon: c.icon,
                      selected: _draft == c.key,
                      onTap: () => setState(() => _draft = c.key),
                      isDark: isDark,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        const _CategoryFilterResult(null),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(isArabic ? 'مسح' : 'Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _CategoryFilterResult(_draft),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isArabic ? 'تطبيق' : 'Apply',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : (isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightSurfaceVariant),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.primary
                    : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: selected
                        ? AppColors.primary
                        : (isDark
                        ? Colors.white
                        : AppColors.lightTextPrimary),
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
            ],
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
    required this.hasFilters,
  });
  final bool isArabic;
  final bool isDark;
  final bool hasFilters;

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
              child: Icon(
                hasFilters
                    ? Icons.search_off_rounded
                    : Icons.handyman_outlined,
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
              hasFilters
                  ? (isArabic ? 'لا توجد نتائج' : 'No matching tools')
                  : (isArabic
                  ? 'لا توجد أدوات معروضة'
                  : 'No tools for sale yet'),
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 10),
            Text(
              hasFilters
                  ? (isArabic
                  ? 'جرّب كلمة أو تصنيفاً آخر.'
                  : 'Try another keyword or category.')
                  : (isArabic
                  ? 'عندما يعرض طبيب أداة، ستظهر هنا.'
                  : 'Tools listed by other doctors will appear here.'),
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