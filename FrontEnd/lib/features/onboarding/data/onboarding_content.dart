import 'package:flutter/material.dart';

/// Static content for the 3 onboarding slides.
///
/// Bilingual: every slide carries AR + EN strings. The active language
/// is selected by the placeholder layer.
@immutable
class OnboardingSlide {
  const OnboardingSlide({
    required this.icon,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.iconColor,
  });

  final IconData icon;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final Color iconColor;
}

const onboardingSlides = <OnboardingSlide>[
  OnboardingSlide(
    icon: Icons.waving_hand_rounded,
    iconColor: Color(0xFF0D6EFD),
    titleAr: 'مرحباً بك في دنت سبيس',
    titleEn: 'Welcome to DentSpace',
    subtitleAr:
    'منصة تربط المرضى بطلاب طب الأسنان المؤهّلين '
        'لتقديم العلاج المجاني تحت إشراف أكاديمي.',
    subtitleEn:
    'A platform connecting patients with supervised '
        'dentistry students for free, verified treatment.',
  ),
  OnboardingSlide(
    icon: Icons.handshake_rounded,
    iconColor: Color(0xFF14B8A6),
    titleAr: 'علاج حقيقي، تدريب حقيقي',
    titleEn: 'Real Care, Real Training',
    subtitleAr:
    'الطلاب يكتسبون خبرة عملية على حالات حقيقية، '
        'وأنت تحصل على رعاية مجانية عالية الجودة.',
    subtitleEn:
    'Students gain hands-on experience on real cases, '
        'while you receive quality treatment — free of charge.',
  ),
  OnboardingSlide(
    icon: Icons.verified_user_rounded,
    iconColor: Color(0xFF10B981),
    titleAr: 'أمان ومصداقية',
    titleEn: 'Safe and Verified',
    subtitleAr:
    'كل حالة يجري توثيقها والتحقق منها من قبل '
        'الإدارة الأكاديمية. بياناتك محمية ولا تُشارك.',
    subtitleEn:
    'Every case is documented and verified by the '
        'academic administration. Your data stays private.',
  ),
];