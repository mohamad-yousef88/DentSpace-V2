import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Responsive sizing based on screen width & text scale
    final double screenWidth = mediaQuery.size.width;
    final double textScale = mediaQuery.textScaler.scale(1.0);

    // Logo bubble size scales between 52 and 64 based on screen width
    // الطريقة الاحترافية
    final double logoSize = (screenWidth * 0.18).clamp(56.0, 72.0);
    final double logoIconSize = logoSize * 0.5;

    // Title font size scales responsively
    final double titleFontSize = (screenWidth * 0.065).clamp(22.0, 28.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Centered logo bubble
        Semantics(
          label: 'App logo',
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: logoIconSize,
            ),
          ),
        ),
        SizedBox(height: (screenWidth * 0.05).clamp(16.0, 24.0)),
        // Centered title
        Text(
          title,
          textAlign: TextAlign.center,
          textScaler: TextScaler.linear(
            textScale.clamp(1.0, 1.2),
          ),
          style: AppTextStyles.headlineLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        // Centered subtitle with constrained width for readability
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            textScaler: TextScaler.linear(
              textScale.clamp(1.0, 1.2),
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.5,
              fontSize: theme.textTheme.bodyMedium?.fontSize,
            ),
          ),
        ),
      ],
    );
  }
}