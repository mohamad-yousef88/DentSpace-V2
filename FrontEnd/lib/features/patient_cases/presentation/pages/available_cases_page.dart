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
import '../bloc/cases_bloc.dart';
import '../bloc/cases_event.dart';
import '../bloc/cases_state.dart';
import '../widgets/case_card.dart';

/// Doctor-facing screen: every `pending` case from other patients.
///
/// Modes:
///   • `embedded = false` (default): full page with [Scaffold]/[AppBar]
///     — pushed from the doctor's quick action.
///   • `embedded = true`: content-only — used as a bottom-nav tab inside
///     [HomeShell].
///
/// Search is debounced (400 ms) before hitting the server.
class AvailableCasesPage extends StatefulWidget {
  const AvailableCasesPage({super.key, this.embedded = false});

  /// Skip the outer [Scaffold]/[AppBar] when hosted in a shell.
  final bool embedded;

  @override
  State<AvailableCasesPage> createState() => _AvailableCasesPageState();
}

class _AvailableCasesPageState extends State<AvailableCasesPage> {
  late final CasesBloc _bloc;
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<CasesBloc>();
    _bloc.add(const LoadAvailableCasesEvent());
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
    // Rebuild so the clear button appears / disappears.
    setState(() {});
    _debouncer.run(() {
      if (!mounted) return;
      _bloc.add(LoadAvailableCasesEvent(
        search: _searchController.text.trim(),
      ),);
    });
  }

  void _reload() {
    _bloc.add(LoadAvailableCasesEvent(
      search: _searchController.text.trim(),
    ),);
  }

  Future<void> _openDetails(int id) async {
    final changed = await context.push<bool>(Routes.caseDetails(id));
    if (changed == true && mounted) {
      _reload();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final body = Column(
      children: [
        _SearchBar(
          controller: _searchController,
          isArabic: isArabic,
          isDark: isDark,
        ),
        Expanded(
          child: BlocConsumer<CasesBloc, CasesState>(
            listener: (context, state) {
              if (state.errorMessage != null &&
                  state.status == CasesStatus.failure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppColors.error,
                  ),);
              }
            },
            builder: (context, state) {
              if (state.isLoading && state.cases.isEmpty) {
                return const Center(
                  child:
                  CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (state.cases.isEmpty) {
                return _EmptyState(
                  isArabic: isArabic,
                  isDark: isDark,
                  hasSearch: _searchController.text.trim().isNotEmpty,
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => _reload(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: state.cases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = state.cases[i];
                    return CaseCard(
                      item: item,
                      showUrgency: true,
                      onTap: () => _openDetails(item.id),
                    )
                        .animate(delay: (i * 60).ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(
                      begin: 0.15,
                      end: 0,
                      duration: 350.ms,
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
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
          scrolledUnderElevation: 0.5,
          leading: IconButton(
            icon: Icon(
              isArabic
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            isArabic ? 'الحالات المتاحة' : 'Available Cases',
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
          hintText: isArabic
              ? 'ابحث حسب الحالة أو الموقع...'
              : 'Search by condition or location...',
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
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ═══════════════════════════════════════════════════════════════
// Empty state
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isArabic,
    required this.isDark,
    required this.hasSearch,
  });
  final bool isArabic;
  final bool isDark;
  final bool hasSearch;

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
                hasSearch
                    ? Icons.search_off_rounded
                    : Icons.medical_services_outlined,
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
              hasSearch
                  ? (isArabic ? 'لا توجد نتائج مطابقة' : 'No matching cases')
                  : (isArabic
                  ? 'لا توجد حالات متاحة حالياً'
                  : 'No available cases right now'),
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 10),
            Text(
              hasSearch
                  ? (isArabic
                  ? 'جرّب كلمة بحث أخرى.'
                  : 'Try a different search term.')
                  : (isArabic
                  ? 'عندما ينشر المرضى حالات جديدة، ستظهر هنا.'
                  : 'When patients post new cases, they will appear here.'),
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