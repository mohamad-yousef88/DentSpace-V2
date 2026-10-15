import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Unified profile screen.
///
/// Modes:
///   • `embedded = false` (default): full page with [Scaffold] + [AppBar]
///     — pushed from the drawer via [Routes.profile].
///   • `embedded = true`: content-only — used as the bottom-nav "Profile"
///     tab inside [HomeShell].
///
/// Layout (top → bottom):
///   1. Avatar (tap → change)
///   2. Name + email
///   3. "Edit information" CTA (opens bottom sheet)
///   4. Personal info card
///   5. Preferences: language · theme
///   6. Support: help · about
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.embedded = false});

  /// Skip the outer [Scaffold]/[AppBar] when hosted in a shell.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final authBloc = GetIt.instance<AuthBloc>();
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ─── Shared body (identical in both modes) ──────────
    final body = BlocProvider.value(
      value: authBloc,
      child: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, c) => p.message != c.message,
        listener: (context, state) {
          if (state.message == 'profile_updated') {
            _snack(context, isArabic ? 'تم تحديث البيانات' : 'Profile updated');
          } else if (state.message == 'avatar_updated') {
            _snack(context, isArabic ? 'تم تحديث الصورة' : 'Avatar updated');
          }
        },
        builder: (context, state) {
          final user = state.user;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              24,
              20,
              embedded ? 100 : 40, // extra space above bottom nav
            ),
            children: [
              // ─── Avatar ────────────────────────────
              Center(
                child: _Avatar(
                  imageUrl: user?.profileImageUrl,
                  name: user?.fullName ?? '?',
                  onTap: () => _pickAvatar(context),
                ),
              ),
              const SizedBox(height: 14),

              // ─── Name + email ──────────────────────
              Center(
                child: Text(
                  user?.fullName ?? '—',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color:
                    isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  user?.email ?? '',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Edit button (hero CTA) ────────────
              FilledButton.icon(
                onPressed: () => _showEditSheet(context, user, isArabic),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(
                  isArabic ? 'تعديل المعلومات' : 'Edit information',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── Personal info card ────────────────
              _InfoCard(user: user, isArabic: isArabic, isDark: isDark),

              // ─── Preferences ───────────────────────
              const SizedBox(height: 24),
              _SectionTitle(
                isArabic: isArabic,
                labelAr: 'التفضيلات',
                labelEn: 'Preferences',
              ),
              const SizedBox(height: 8),
              _Card(
                isDark: isDark,
                children: [
                  _Tile(
                    icon: Icons.language_rounded,
                    titleAr: 'اللغة',
                    titleEn: 'Language',
                    trailingText: isArabic ? 'العربية' : 'English',
                    onTap: () => context.read<LocalizationCubit>().toggle(),
                  ),
                  _divider(isDark),
                  _Tile(
                    icon: switch (context.watch<ThemeCubit>().state) {
                      ThemeMode.system => Icons.brightness_auto,
                      ThemeMode.light => Icons.light_mode_outlined,
                      ThemeMode.dark => Icons.dark_mode_outlined,
                    },
                    titleAr: 'المظهر',
                    titleEn: 'Theme',
                    trailingText: switch (context.watch<ThemeCubit>().state) {
                      ThemeMode.system => isArabic ? 'تلقائي' : 'Auto',
                      ThemeMode.light => isArabic ? 'فاتح' : 'Light',
                      ThemeMode.dark => isArabic ? 'داكن' : 'Dark',
                    },
                    onTap: () => context.read<ThemeCubit>().toggle(),
                  ),
                ],
              ),

              // ─── Support ───────────────────────────
              const SizedBox(height: 24),
              _SectionTitle(
                isArabic: isArabic,
                labelAr: 'الدعم والمعلومات',
                labelEn: 'Support & Info',
              ),
              const SizedBox(height: 8),
              _Card(
                isDark: isDark,
                children: [
                  _Tile(
                    icon: Icons.help_outline_rounded,
                    titleAr: 'المساعدة والدعم',
                    titleEn: 'Help & Support',
                    onTap: () => context.push(Routes.support),
                  ),
                  _divider(isDark),
                  _Tile(
                    icon: Icons.info_outline_rounded,
                    titleAr: 'حول التطبيق',
                    titleEn: 'About DentSpace',
                    onTap: () => context.push(Routes.about),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // ─── Mode: embedded tab ─────────────────────────────
    if (embedded) return body;

    // ─── Mode: standalone full page ─────────────────────
    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isArabic ? 'الملف الشخصي' : 'Profile',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: body,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════
  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
      ),);
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file == null) return;
    GetIt.instance<AuthBloc>().add(UploadAvatarRequested(
      filePath: file.path,
      fileName: file.name,
    ),);
  }

  void _showEditSheet(BuildContext context, UserEntity? user, bool isArabic) {
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditSheet(user: user, isArabic: isArabic),
    );
  }

  static Widget _divider(bool isDark) => Divider(
    height: 1,
    indent: 56,
    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
  );
}

// ═══════════════════════════════════════════════════════════════
// Section title
// ═══════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.isArabic,
    required this.labelAr,
    required this.labelEn,
  });
  final bool isArabic;
  final String labelAr;
  final String labelEn;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Text(
        isArabic ? labelAr : labelEn,
        style: AppTextStyles.labelLarge.copyWith(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Card wrapper
// ═══════════════════════════════════════════════════════════════
class _Card extends StatelessWidget {
  const _Card({required this.isDark, required this.children});
  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(children: children),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Avatar (with camera badge)
// ═══════════════════════════════════════════════════════════════
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.imageUrl,
    required this.name,
    required this.onTap,
  });
  final String? imageUrl;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            alignment: Alignment.center,
            child: hasImage
                ? ClipOval(
              child: Image.network(
                imageUrl!,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
                : Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Personal info card
// ═══════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.user,
    required this.isArabic,
    required this.isDark,
  });
  final UserEntity? user;
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      children: [
        _row(Icons.person_outline_rounded,
            isArabic ? 'الاسم' : 'Name', user?.fullName ?? '—',),
        _divider(),
        _row(Icons.email_outlined,
            isArabic ? 'البريد' : 'Email', user?.email ?? '—',),
        _divider(),
        _row(Icons.phone_outlined,
            isArabic ? 'الهاتف' : 'Phone', user?.phone ?? '—',),
        if (user?.age != null) ...[
          _divider(),
          _row(Icons.cake_outlined,
              isArabic ? 'العمر' : 'Age', '${user!.age}',),
        ],
        if (user?.gender != null) ...[
          _divider(),
          _row(
            Icons.wc_rounded,
            isArabic ? 'الجنس' : 'Gender',
            user!.gender == 'male'
                ? (isArabic ? 'ذكر' : 'Male')
                : (isArabic ? 'أنثى' : 'Female'),
          ),
        ],
      ],
    );
  }

  Widget _divider() => Divider(
    height: 1,
    indent: 56,
    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
  );

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color:
              isDark ? Colors.white60 : AppColors.lightTextSecondary,),
          const SizedBox(width: 14),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Tile (settings-style row)
// ═══════════════════════════════════════════════════════════════
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.titleAr,
    required this.titleEn,
    required this.onTap,
    this.trailingText,
  });
  final IconData icon;
  final String titleAr;
  final String titleEn;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';

    return ListTile(
      leading: Icon(icon,
          color: isDark ? Colors.white70 : AppColors.primary, size: 22,),
      title: Text(
        isArabic ? titleAr : titleEn,
        style: AppTextStyles.bodyLarge.copyWith(
          color: isDark ? Colors.white : AppColors.lightTextPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Edit bottom sheet
// ═══════════════════════════════════════════════════════════════
class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.user, required this.isArabic});
  final UserEntity user;
  final bool isArabic;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _ageCtrl;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.fullName);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _ageCtrl = TextEditingController(text: widget.user.age?.toString() ?? '');
    _gender = widget.user.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final age = int.tryParse(_ageCtrl.text.trim());
    GetIt.instance<AuthBloc>().add(UpdateProfileSubmitted(
      fullName: _nameCtrl.text.trim().isEmpty
          ? null
          : _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty
          ? null
          : _phoneCtrl.text.trim(),
      gender: _gender,
      age: age,
    ),);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isArabic ? 'تعديل المعلومات' : 'Edit information',
                style: AppTextStyles.titleLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: isArabic ? 'الاسم الكامل' : 'Full name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: isArabic ? 'الهاتف' : 'Phone',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isArabic ? 'العمر' : 'Age',
                  prefixIcon: const Icon(Icons.cake_outlined),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(isArabic ? 'ذكر' : 'Male'),
                      selected: _gender == 'male',
                      onSelected: (_) => setState(() => _gender = 'male'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(isArabic ? 'أنثى' : 'Female'),
                      selected: _gender == 'female',
                      onSelected: (_) => setState(() => _gender = 'female'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isArabic ? 'حفظ' : 'Save',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}