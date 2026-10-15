import 'package:flutter/widgets.dart';

/// One entry in the home bottom navigation bar.
class HomeTab {
  const HomeTab({
    required this.icon,
    required this.activeIcon,
    required this.labelAr,
    required this.labelEn,
    required this.page,
  });

  final IconData icon;
  final IconData activeIcon;
  final String labelAr;
  final String labelEn;
  final Widget page;
}