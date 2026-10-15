import 'package:equatable/equatable.dart';

/// A single symptom with a bilingual display label.
///
/// The [key] field is the canonical Arabic string sent to the backend
/// (the symptom analyzer matches on these labels). The [ar] / [en]
/// fields drive what the user sees.
class SymptomItem extends Equatable {
  const SymptomItem({
    required this.key,
    required this.ar,
    required this.en,
  });

  final String key;   // Arabic — send this to the backend
  final String ar;    // Arabic — display
  final String en;    // English — display

  String labelFor({required bool isArabic}) => isArabic ? ar : en;

  @override
  List<Object?> get props => [key];
}

/// A group of symptoms sharing a clinical theme.
class SymptomGroup extends Equatable {
  const SymptomGroup({
    required this.titleAr,
    required this.titleEn,
    required this.symptoms,
  });

  final String titleAr;
  final String titleEn;
  final List<SymptomItem> symptoms;

  String titleFor({required bool isArabic}) => isArabic ? titleAr : titleEn;

  @override
  List<Object?> get props => [titleAr];
}

/// A jaw location with a bilingual label.
class LocationItem extends Equatable {
  const LocationItem({
    required this.key,   // Arabic — send to backend
    required this.ar,
    required this.en,
  });

  final String key;
  final String ar;
  final String en;

  String labelFor({required bool isArabic}) => isArabic ? ar : en;

  @override
  List<Object?> get props => [key];
}

/// A severity level with a bilingual label.
class SeverityItem extends Equatable {
  const SeverityItem({
    required this.key,   // Arabic — send to backend
    required this.ar,
    required this.en,
  });

  final String key;
  final String ar;
  final String en;

  String labelFor({required bool isArabic}) => isArabic ? ar : en;

  @override
  List<Object?> get props => [key];
}

// ═══════════════════════════════════════════════════════════════
// Catalogue
// ═══════════════════════════════════════════════════════════════
const kLocations = <LocationItem>[
  LocationItem(
    key: 'الفك العلوي الأيسر',
    ar: 'الفك العلوي الأيسر',
    en: 'Upper left jaw',
  ),
  LocationItem(
    key: 'الفك العلوي الأيمن',
    ar: 'الفك العلوي الأيمن',
    en: 'Upper right jaw',
  ),
  LocationItem(
    key: 'الفك السفلي الأيسر',
    ar: 'الفك السفلي الأيسر',
    en: 'Lower left jaw',
  ),
  LocationItem(
    key: 'الفك السفلي الأيمن',
    ar: 'الفك السفلي الأيمن',
    en: 'Lower right jaw',
  ),
];

const kSeverities = <SeverityItem>[
  SeverityItem(key: 'خفيف', ar: 'خفيف', en: 'Mild'),
  SeverityItem(key: 'متوسط', ar: 'متوسط', en: 'Moderate'),
  SeverityItem(key: 'شديد', ar: 'شديد', en: 'Severe'),
];

const kSymptomGroups = <SymptomGroup>[
  SymptomGroup(
    titleAr: 'تآكل الميناء (نخر)',
    titleEn: 'Enamel erosion (caries)',
    symptoms: [
      SymptomItem(
        key: 'ألم في مكان النخر',
        ar: 'ألم في مكان النخر',
        en: 'Pain at the cavity site',
      ),
      SymptomItem(
        key: 'حساسية للمشروبات الباردة أوالساخنة',
        ar: 'حساسية للمشروبات الباردة أوالساخنة',
        en: 'Sensitivity to hot / cold drinks',
      ),
      SymptomItem(
        key: 'ثقوب أو تجاويف ظاهرة',
        ar: 'ثقوب أو تجاويف ظاهرة',
        en: 'Visible cavities or holes',
      ),
      SymptomItem(
        key: 'ألم عند المضغ',
        ar: 'ألم عند المضغ',
        en: 'Pain while chewing',
      ),
    ],
  ),
  SymptomGroup(
    titleAr: 'التهاب عصب السن',
    titleEn: 'Dental pulp inflammation',
    symptoms: [
      SymptomItem(
        key: 'وخز في المنطقة المحيطة بالسن',
        ar: 'وخز في المنطقة المحيطة بالسن',
        en: 'Stinging around the tooth',
      ),
      SymptomItem(
        key: 'ورم في اللثة المحيطة',
        ar: 'ورم في اللثة المحيطة',
        en: 'Swelling of the surrounding gum',
      ),
      SymptomItem(
        key: 'صداع قوي',
        ar: 'صداع قوي',
        en: 'Severe headache',
      ),
      SymptomItem(
        key: 'نزيف لثوي',
        ar: 'نزيف لثوي',
        en: 'Gum bleeding',
      ),
    ],
  ),
  SymptomGroup(
    titleAr: 'تراجع اللثة',
    titleEn: 'Gum recession',
    symptoms: [
      SymptomItem(
        key: 'انحسار اللثة',
        ar: 'انحسار اللثة',
        en: 'Gum recession',
      ),
      SymptomItem(
        key: 'رائحة كريهة للفم',
        ar: 'رائحة كريهة للفم',
        en: 'Bad breath',
      ),
      SymptomItem(
        key: 'طعم سيء أو إقياء',
        ar: 'طعم سيء أو إقياء',
        en: 'Bad taste or nausea',
      ),
      SymptomItem(
        key: 'اهتزاز السن',
        ar: 'اهتزاز السن',
        en: 'Loose tooth',
      ),
      SymptomItem(
        key: 'ألم أو حكة في اللثة',
        ar: 'ألم أو حكة في اللثة',
        en: 'Gum pain or itching',
      ),
    ],
  ),
  SymptomGroup(
    titleAr: 'قلع سن',
    titleEn: 'Tooth extraction',
    symptoms: [
      SymptomItem(
        key: 'تسوس شديد يغطي السن بالكامل',
        ar: 'تسوس شديد يغطي السن بالكامل',
        en: 'Severe decay covering the whole tooth',
      ),
      SymptomItem(
        key: 'أمراض لثوية مع التسوس',
        ar: 'أمراض لثوية مع التسوس',
        en: 'Gum disease along with decay',
      ),
      SymptomItem(
        key: 'خراجات متكررة في نفس المنطقة',
        ar: 'خراجات متكررة في نفس المنطقة',
        en: 'Recurrent abscesses in the same area',
      ),
      SymptomItem(
        key: 'كسر في الجذر أو تحت العظم',
        ar: 'كسر في الجذر أو تحت العظم',
        en: 'Root fracture or below-bone damage',
      ),
    ],
  ),
  SymptomGroup(
    titleAr: 'أخرى',
    titleEn: 'Other',
    symptoms: [
      SymptomItem(
        key: 'ألم نابض',
        ar: 'ألم نابض',
        en: 'Throbbing pain',
      ),
      SymptomItem(
        key: 'تورم في الوجه أو اللثة',
        ar: 'تورم في الوجه أو اللثة',
        en: 'Swelling in the face or gum',
      ),
      SymptomItem(
        key: 'حمى أو ارتفاع حرارة',
        ar: 'حمى أو ارتفاع حرارة',
        en: 'Fever or high temperature',
      ),
      SymptomItem(
        key: 'ألم يوقظ من النوم',
        ar: 'ألم يوقظ من النوم',
        en: 'Pain that wakes you from sleep',
      ),
      SymptomItem(
        key: 'ناسور فموي (فتحة صغيرة تخرج منها سوائل)',
        ar: 'ناسور فموي (فتحة صغيرة تخرج منها سوائل)',
        en: 'Oral fistula (small draining opening)',
      ),
      SymptomItem(
        key: 'إصابة أو كسر سن نتيجة رض',
        ar: 'إصابة أو كسر سن نتيجة رض',
        en: 'Tooth injury or fracture from trauma',
      ),
      SymptomItem(
        key: 'انقلاع كامل للسن من مكانه',
        ar: 'انقلاع كامل للسن من مكانه',
        en: 'Complete tooth avulsion',
      ),
      SymptomItem(
        key: 'السن يبدو أطول من جيرانه',
        ar: 'السن يبدو أطول من جيرانه',
        en: 'Tooth appears longer than neighbours',
      ),
      SymptomItem(
        key: 'ألم شديد عند المضغ',
        ar: 'ألم شديد عند المضغ',
        en: 'Severe pain while chewing',
      ),
      SymptomItem(
        key: 'صعوبة في فتح الفم',
        ar: 'صعوبة في فتح الفم',
        en: 'Difficulty opening the mouth',
      ),
      SymptomItem(
        key: 'ألم في زاوية الفك الخلفية',
        ar: 'ألم في زاوية الفك الخلفية',
        en: 'Pain at the back of the jaw',
      ),
      SymptomItem(
        key: 'تورم اللثة حول السن الأخير',
        ar: 'تورم اللثة حول السن الأخير',
        en: 'Gum swelling around the last tooth',
      ),
    ],
  ),
];