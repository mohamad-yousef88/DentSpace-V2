import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/cases_bloc.dart';
import '../bloc/cases_event.dart';
import '../bloc/cases_state.dart';
import '../widgets/case_card.dart';

/// Patient's own cases list.
///
/// Modes:
///   • `embedded = false` (default): full page with its own [Scaffold],
///     [AppBar] and [FloatingActionButton] — pushed via the router.
///   • `embedded = true`: content-only — used as a bottom-nav tab inside
///     [HomeShell].
///
/// Content, refresh, empty state, and navigation are identical in both
/// modes; only chrome differs.
class CasesListPage extends StatefulWidget {
  const CasesListPage({super.key, this.embedded = false});

  /// Skip the outer [Scaffold]/[AppBar] when hosted in a shell.
  final bool embedded;

  @override
  State<CasesListPage> createState() => _CasesListPageState();
}

class _CasesListPageState extends State<CasesListPage> {
  late final CasesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<CasesBloc>();
    _bloc.add(const LoadMyCasesEvent());
  }

  // ═══════════════════════════════════════════════════════════════
  Future<void> _openNewCase() async {
    final created = await context.push<bool>(Routes.caseNew);
    if (created == true && mounted) {
      _bloc.add(const LoadMyCasesEvent());
    }
  }

  Future<void> _openDetails(int id) async {
    final changed = await context.push<bool>(Routes.caseDetails(id));
    if (changed == true && mounted) {
      _bloc.add(const LoadMyCasesEvent());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ─── Shared body ────────────────────────────────────
    final body = BlocConsumer<CasesBloc, CasesState>(
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
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state.cases.isEmpty) {
          return _EmptyState(isArabic: isArabic);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _bloc.add(const LoadMyCasesEvent()),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              widget.embedded ? 100 : 100,
            ),
            itemCount: state.cases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final item = state.cases[i];
              return CaseCard(
                item: item,
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
    );

    // ─── Shared FAB ─────────────────────────────────────
    final fab = FloatingActionButton.extended(
      heroTag: widget.embedded ? 'cases_tab_fab' : 'cases_page_fab',
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      onPressed: _openNewCase,
      icon: const Icon(Icons.add_rounded),
      label: Text(isArabic ? 'حالة جديدة' : 'New case'),
    );

    // ─── Mode: embedded tab ─────────────────────────────
    if (widget.embedded) {
      return BlocProvider.value(
        value: _bloc,
        child: Stack(
          children: [
            body,
            Positioned(right: 16, bottom: 16, child: fab),
          ],
        ),
      );
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
            isArabic ? 'حالاتي' : 'My Cases',
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: AppColors.primary,
              onPressed: _openNewCase,
            ),
          ],
        ),
        body: body,
        floatingActionButton: fab,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Empty state
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                Icons.folder_open_rounded,
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
              isArabic ? 'لا توجد حالات بعد' : 'No cases yet',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 10),
            Text(
              isArabic
                  ? 'اضغط "حالة جديدة" لوصف حالتك والحصول على تشخيص أولي.'
                  : 'Tap "New case" to describe your symptoms and get a preliminary diagnosis.',
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