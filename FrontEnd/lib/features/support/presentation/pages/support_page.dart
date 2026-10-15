import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Help & Support page.
///
/// Sections:
///   1. Hero — gradient circle + title + subtitle
///   2. Contact methods — Email · Phone · WhatsApp
///   3. FAQ — expandable accordion
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          isArabic ? 'المساعدة والدعم' : 'Help & Support',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _Hero(isArabic: isArabic, isDark: isDark)
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.15, end: 0, duration: 500.ms,
              curve: Curves.easeOutCubic,),

          const SizedBox(height: 32),

          _SectionTitle(
            isArabic: isArabic,
            labelAr: 'تواصل معنا',
            labelEn: 'Contact us',
          ).animate(delay: 150.ms).fadeIn(),

          const SizedBox(height: 12),

          const _ContactCard(
            icon: Icons.email_outlined,
            titleAr: 'البريد الإلكتروني',
            titleEn: 'Email',
            value: 'support@dentspace.app',
            color: AppColors.primary,
          ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.05, end: 0),

          const SizedBox(height: 10),
          const _ContactCard(
            icon: Icons.phone_outlined,
            titleAr: 'الهاتف',
            titleEn: 'Phone',
            value: '+963 900 000 000',
            color: AppColors.secondary,
          ).animate(delay: 250.ms).fadeIn().slideX(begin: 0.05, end: 0),

          const SizedBox(height: 10),
          const _ContactCard(
            icon: Icons.chat_bubble_outline_rounded,
            titleAr: 'واتساب',
            titleEn: 'WhatsApp',
            value: '+963 900 000 000',
            color: AppColors.success,
          ).animate(delay: 300.ms).fadeIn().slideX(begin: 0.05, end: 0),

          const SizedBox(height: 32),

          _SectionTitle(
            isArabic: isArabic,
            labelAr: 'الأسئلة الشائعة',
            labelEn: 'Frequently asked',
          ).animate(delay: 350.ms).fadeIn(),

          const SizedBox(height: 12),

          ..._buildFaqs(isArabic, isDark),

          const SizedBox(height: 32),

          _ReportBanner(isArabic: isArabic).animate(delay: 700.ms).fadeIn(),
        ],
      ),
    );
  }

  // ─── FAQ data + widgets ──────────────────────────────
  List<Widget> _buildFaqs(bool isArabic, bool isDark) {
    final faqs = [
      (
      qAr: 'كيف أنشئ حالة جديدة؟',
      qEn: 'How do I create a new case?',
      aAr:
      'من الصفحة الرئيسية اضغط على "حالة جديدة"، صِف الأعراض بدقة، أضف صورة إن أمكن، ثم أكّد الحفظ. سيُراجع أطباء مؤهّلون حالتك قريباً.',
      aEn:
      'From the home screen, tap "New case", describe your symptoms accurately, optionally attach an image, then confirm. Verified doctors will review your case shortly.',
      ),
      (
      qAr: 'كيف يتم اختيار الطبيب؟',
      qEn: 'How is the doctor selected?',
      aAr:
      'الأطباء المُعتمدون يرسلون طلبات حجز على حالتك. يمكنك الاطّلاع على بياناتهم واختيار الأنسب لك قبل الموافقة. أي طلبات أخرى تُرفض تلقائياً.',
      aEn:
      'Verified doctors send booking requests for your case. You can review their profiles and approve the best fit. Other pending requests are automatically rejected.',
      ),
      (
      qAr: 'هل الخدمة مجانية فعلاً؟',
      qEn: 'Is the service really free?',
      aAr:
      'نعم — الفحص المبدئي والتواصل مع الطبيب مجاني بالكامل. لا توجد أي رسوم خفية.',
      aEn:
      'Yes — preliminary screening and doctor contact are completely free. There are no hidden fees.',
      ),
      (
      qAr: 'كم يستغرق الرد عادة؟',
      qEn: 'How long does a response usually take?',
      aAr:
      'عادةً خلال 24 ساعة. الحالات الطارئة (emergency) تحصل على أولوية قصوى.',
      aEn:
      'Usually within 24 hours. Emergency cases get top priority.',
      ),
      (
      qAr: 'ماذا أفعل في الحالات الطارئة؟',
      qEn: 'What about emergencies?',
      aAr:
      'إذا أشار النظام إلى حالة "طارئة"، توجّه فوراً لأقرب مركز طوارئ. التطبيق أداة مساعدة وليس بديلاً عن الرعاية العاجلة.',
      aEn:
      'If the app flags "Emergency", go to the nearest ER immediately. The app assists but never replaces urgent care.',
      ),
      (
      qAr: 'هل بياناتي محفوظة بأمان؟',
      qEn: 'Is my data secure?',
      aAr:
      'نعم. جميع البيانات الحساسة (كلمات المرور، الصور، المعلومات الطبية) مشفّرة. الصور مخزّنة على Cloudinary، والتوكنات على التخزين الآمن بالجهاز.',
      aEn:
      'Yes. All sensitive data (passwords, images, medical records) is encrypted. Images live on Cloudinary; tokens use the device\'s secure storage.',
      ),
      (
      qAr: 'كيف أغيّر كلمة المرور؟',
      qEn: 'How do I change my password?',
      aAr:
      'من شاشة تسجيل الدخول، اضغط "نسيت كلمة المرور"، أدخل بريدك، ثم اتبع رمز OTP الذي يصلك بالبريد لتعيين كلمة جديدة.',
      aEn:
      'From the login screen, tap "Forgot password", enter your email, then follow the OTP sent to your inbox to set a new password.',
      ),
      (
      qAr: 'كيف أُعدّل بياناتي الشخصية؟',
      qEn: 'How do I edit my personal info?',
      aAr:
      'من تبويب "حسابي" في الشريط السفلي، اضغط "تعديل المعلومات"، حدّث ما تريد ثم احفظ. يمكنك أيضاً تغيير صورتك بالضغط على الصورة الرمزية.',
      aEn:
      'In the bottom nav, open "Profile", tap "Edit information", update your data and save. Tap the avatar to change your photo.',
      ),
    ];

    return List.generate(faqs.length, (i) {
      final faq = faqs[i];
      return _FaqTile(
        questionAr: faq.qAr,
        questionEn: faq.qEn,
        answerAr: faq.aAr,
        answerEn: faq.aEn,
        isArabic: isArabic,
      ).animate(delay: (400 + i * 40).ms).fadeIn().slideY(
        begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut,
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════
// Hero
// ═══════════════════════════════════════════════════════════════
class _Hero extends StatelessWidget {
  const _Hero({required this.isArabic, required this.isDark});
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.10),
            AppColors.secondary.withValues(alpha: isDark ? 0.14 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 44,
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
            begin: const Offset(0.7, 0.7),
            end: const Offset(1, 1),
            duration: 600.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'نحن هنا لمساعدتك' : 'We are here to help',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'فريق الدعم جاهز للإجابة على أسئلتك خلال 24 ساعة'
                : 'Our team is ready to answer within 24 hours',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Contact card
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// Contact card — NOW WITH WORKING COPY
// ═══════════════════════════════════════════════════════════════
class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.titleAr,
    required this.titleEn,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String titleAr;
  final String titleEn;
  final String value;
  final Color color;

  Future<void> _copy(BuildContext context, bool isArabic) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(isArabic ? 'تم النسخ' : 'Copied'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _copy(context, isArabic),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? titleAr : titleEn,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _copy(context, isArabic),
                tooltip: isArabic ? 'نسخ' : 'Copy',
                icon: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
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
// FAQ tile
// ═══════════════════════════════════════════════════════════════
class _FaqTile extends StatefulWidget {
  const _FaqTile({
    required this.questionAr,
    required this.questionEn,
    required this.answerAr,
    required this.answerEn,
    required this.isArabic,
  });

  final String questionAr;
  final String questionEn;
  final String answerAr;
  final String answerEn;
  final bool isArabic;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: _expanded ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.isArabic
                            ? widget.questionAr
                            : widget.questionEn,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      turns: _expanded ? 0.5 : 0,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      widget.isArabic
                          ? widget.answerAr
                          : widget.answerEn,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
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
// Report banner
// ═══════════════════════════════════════════════════════════════
class _ReportBanner extends StatelessWidget {
  const _ReportBanner({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bug_report_outlined,
            color: AppColors.warning,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'واجهت مشكلة؟' : 'Found a problem?',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? Colors.white
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'أخبرنا وسنصلحها في أسرع وقت'
                      : 'Tell us and we will fix it fast',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(
                    isArabic
                        ? 'شكراً — سنتواصل معك قريباً'
                        : 'Thanks — we will reach out soon',
                  ),
                  backgroundColor: AppColors.success,
                ),);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isArabic ? 'إبلاغ' : 'Report',
              style: const TextStyle(
                fontSize: 13,
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