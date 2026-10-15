import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../localization/localization_cubit.dart';
import '../../router/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/theme_cubit.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../features/auth/presentation/bloc/auth_state.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final themeMode = context.watch<ThemeCubit>().state;

    final authBloc = GetIt.instance<AuthBloc>();

    return Drawer(
      backgroundColor:
      isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: SafeArea(
        child: BlocProvider.value(
          value: authBloc,
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = state.user;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── User header ────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.05),
                        ]
                            : [
                          AppColors.primary.withValues(alpha: 0.12),
                          AppColors.primary.withValues(alpha: 0.03),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        _Avatar(
                          imageUrl: user?.profileImageUrl,
                          name: user?.fullName ?? '?',
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ??
                                    (isArabic ? 'جارٍ التحميل' : 'Loading...'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Menu ───────────────────────────────
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // ★ All drawer items use `push` so the back
                        //   button on the destination works correctly.
                        _DrawerItem(
                          icon: Icons.person_outline_rounded,
                          titleAr: 'الملف الشخصي',
                          titleEn: 'Profile',
                          onTap: () {
                            Navigator.pop(context);
                            context.push(Routes.profile);
                          },
                        ),
                        if (user?.isDoctor ?? false)
                          _DrawerItem(
                            icon: Icons.inventory_2_outlined,
                            titleAr: 'أدواتي',
                            titleEn: 'My Tools',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.myTools);
                            },
                          ),
                        if (user?.isDoctor ?? false)
                          _DrawerItem(
                            icon: Icons.receipt_long_outlined,
                            titleAr: 'طلباتي',
                            titleEn: 'My Orders',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.orders);
                            },
                          ),

                        _DrawerItem(
                          icon: Icons.help_outline_rounded,
                          titleAr: 'المساعدة والدعم',
                          titleEn: 'Help & Support',
                          onTap: () {
                            Navigator.pop(context);
                            context.push(Routes.support);
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.info_outline_rounded,
                          titleAr: 'حول التطبيق',
                          titleEn: 'About',
                          onTap: () {
                            Navigator.pop(context);
                            context.push(Routes.about);
                          },
                        ),
                        const Divider(height: 24, indent: 20, endIndent: 20),
                        _DrawerItem(
                          icon: Icons.language_rounded,
                          titleAr: 'تغيير اللغة',
                          titleEn: 'Change language',
                          trailingText: isArabic ? 'AR' : 'EN',
                          onTap: () =>
                              context.read<LocalizationCubit>().toggle(),
                        ),
                        _DrawerItem(
                          icon: switch (themeMode) {
                            ThemeMode.system => Icons.brightness_auto,
                            ThemeMode.light => Icons.light_mode_outlined,
                            ThemeMode.dark => Icons.dark_mode_outlined,
                          },
                          titleAr: 'المظهر',
                          titleEn: 'Theme',
                          trailingText: switch (themeMode) {
                            ThemeMode.system =>
                            isArabic ? 'تلقائي' : 'Auto',
                            ThemeMode.light => isArabic ? 'فاتح' : 'Light',
                            ThemeMode.dark => isArabic ? 'داكن' : 'Dark',
                          },
                          onTap: () => context.read<ThemeCubit>().toggle(),
                        ),
                      ],
                    ),
                  ),

                  // ─── Logout ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Material(
                      color: AppColors.error.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.pop(context);
                          context
                              .read<AuthBloc>()
                              .add(const LogoutRequested());
                          context.go(Routes.splash);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isArabic ? 'تسجيل الخروج' : 'Logout',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl, required this.name});
  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      alignment: Alignment.center,
      child: hasImage
          ? ClipOval(
        child: Image.network(
          imageUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      )
          : Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.titleAr,
    required this.titleEn,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String titleAr;
  final String titleEn;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';

    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: isDark ? Colors.white70 : AppColors.primary,
      ),
      title: Text(
        isArabic ? titleAr : titleEn,
        style: AppTextStyles.bodyLarge.copyWith(
          color: isDark ? Colors.white : AppColors.lightTextPrimary,
        ),
      ),
      trailing: trailingText == null
          ? null
          : Text(
        trailingText!,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
        ),
      ),
      onTap: onTap,
    );
  }
}