import 'symptom_catalogue.dart';

/// Bilingual display labels for values that the backend returns in Arabic.
///
/// The backend is Arabic-native (its symptom analyzer matches Arabic
/// strings), so condition names, locations, symptoms, warnings, red
/// flags, and severity words arrive in Arabic. We keep the canonical
/// Arabic string as the key and provide an English label purely for
/// display.
///
/// Falls back to the original Arabic string when a translation is missing.
///
/// NOTE: Always design UI with Arabic-first in mind — RTL layouts, longer
/// strings, and RTL-aware iconography are first-class concerns, not
/// afterthoughts.

// ═══════════════════════════════════════════════════════════════
// Condition names
// ═══════════════════════════════════════════════════════════════
const _conditionEn = <String, String>{
  // Caries
  'تسوس الأسنان': 'Dental caries',
  'تسوس ثانوي تحت حشوة': 'Recurrent caries under a filling',
  'حساسية الأسنان': 'Dentin hypersensitivity',
  // Pulp
  'التهاب لب السن الحاد': 'Acute pulpitis',
  'التهاب لب السن المزمن': 'Chronic pulpitis',
  'موت لب السن (نخر)': 'Pulp necrosis',
  // Periapical
  'خراج حول الذروة الحاد': 'Acute apical abscess',
  'خراج حول الذروة المزمن': 'Chronic apical abscess',
  'ورم حبيبي حول الذروة': 'Periapical granuloma',
  // Periodontal
  'التهاب اللثة': 'Gingivitis',
  'التهاب دواعم السن': 'Periodontitis',
  'تراجع اللثة': 'Gingival recession',
  'خراج لثوي': 'Gingival abscess',
  'التهاب حوائط التاج (ضرس العقل)': 'Pericoronitis (wisdom tooth)',
  // Mucosal
  'قرحة فموية (قوباء)': 'Aphthous ulcer',
  'السلاق الفموي (فطري)': 'Oral candidiasis',
  'تشقق زوايا الفم': 'Angular cheilitis',
  // Trauma
  'كسر السن': 'Tooth fracture',
  'انقلاع كامل للسن': 'Complete tooth avulsion',
  // Developmental
  'نقص تَمَعْدُن المينا': 'Enamel hypoplasia',
  'تبقّع الفلورايد': 'Fluorosis',
  'سن مدفون': 'Impacted tooth',
  // Functional
  'صرير الأسنان': 'Bruxism',
  'اضطراب مفصل الفك': 'TMJ disorder',
  // Other
  'السنخ الجاف (بعد الخلع)': 'Dry socket',
};

// ═══════════════════════════════════════════════════════════════
// Locations
// ═══════════════════════════════════════════════════════════════
const _locationEn = <String, String>{
  'الفك العلوي الأيسر': 'Upper left jaw',
  'الفك العلوي الأيمن': 'Upper right jaw',
  'الفك السفلي الأيسر': 'Lower left jaw',
  'الفك السفلي الأيمن': 'Lower right jaw',
};

// ═══════════════════════════════════════════════════════════════
// Severity words
// ═══════════════════════════════════════════════════════════════
const _severityEn = <String, String>{
  'خفيف': 'Mild',
  'متوسط': 'Moderate',
  'شديد': 'Severe',
};

// ═══════════════════════════════════════════════════════════════
// Urgency codes
// ═══════════════════════════════════════════════════════════════
const _urgencyEn = <String, String>{
  'routine': 'Routine',
  'soon': 'Within days',
  'urgent': 'Urgent — 24–48h',
  'emergency': 'Emergency — now',
};

const _urgencyAr = <String, String>{
  'routine': 'روتيني',
  'soon': 'خلال أيام',
  'urgent': 'عاجل — 24–48 ساعة',
  'emergency': 'طارئ — فوراً',
};

// ═══════════════════════════════════════════════════════════════
// Warning templates (fixed, not interpolated)
// ═══════════════════════════════════════════════════════════════
const _warningEn = <String, String>{
  'الثقة في التشخيص متوسطة — يُنصح بمتابعة طبية لتقييم أدق.':
  'Moderate diagnostic confidence — a medical follow-up is recommended.',
  'لديك علامات تحذيرية تستدعي التوجه للطوارئ فوراً — لا تنتظر موعداً عادياً.':
  'You have red-flag signs requiring an immediate ER visit — do not wait for a regular appointment.',
};

// ═══════════════════════════════════════════════════════════════
// Red flags
// ═══════════════════════════════════════════════════════════════
const _redFlagEn = <String, String>{
  'تورم ينتشر إلى العين أو الرقبة':
  'Swelling spreading to the eye or neck',
  'صعوبة في البلع أو التنفس':
  'Difficulty swallowing or breathing',
  'حمى أو ارتفاع حرارة':
  'Fever or elevated temperature',
  'نزيف فموي غزير لا يتوقف':
  'Heavy oral bleeding that does not stop',
  'إصابة أو كسر سن نتيجة رض':
  'Tooth injury or fracture from trauma',
  'ألم لا يزول بالمسكنات':
  'Pain not relieved by painkillers',
  'تورم يغلق العين':
  'Swelling that closes the eye',
  'انقلاع كامل للسن من مكانه':
  'Complete tooth avulsion',
};

// ═══════════════════════════════════════════════════════════════
// Emergency instructions
// ═══════════════════════════════════════════════════════════════
const _emergencyInstructionEn = <String, String>{
  'توجه إلى أقرب قسم طوارئ أسنان فوراً.':
  'Go to the nearest dental emergency department immediately.',
  'إن كان هناك تورم في الوجه، ضع كمادات باردة من الخارج.':
  'If there is facial swelling, apply cold compresses externally.',
  'تجنب استعمال الحرارة الموضعية على الوجه.':
  'Avoid applying local heat to the face.',
  'يمكنك تناول مسكن ألم متاح (مثل الباراسيتامول) مؤقتاً.':
  'You may take an available painkiller (such as paracetamol) temporarily.',
  'لا تحاول فتح الخراج بنفسك.':
  'Do not attempt to open the abscess yourself.',
  'اصطحب معك أي تقارير طبية أو صور أشعة إن كانت متوفرة.':
  'Bring any medical reports or X-rays if available.',
};

// ═══════════════════════════════════════════════════════════════
// Symptom lookup — derived from symptom_catalogue.
// ═══════════════════════════════════════════════════════════════
final _symptomEn = <String, String>{
  for (final group in kSymptomGroups)
    for (final item in group.symptoms) item.key: item.en,
};

// ═══════════════════════════════════════════════════════════════
// Clinical notes — keyed by stable `condition.key` (not by Arabic text).
// ═══════════════════════════════════════════════════════════════
const _notesEn = <String, String>{
  'dental_caries':
  'Progressive erosion of tooth enamel caused by bacterial acids '
      'produced from sugar breakdown. Starts silently, then causes '
      'sensitivity and pain.',
  'recurrent_caries':
  'New decay forming at the margins of an old filling due to micro-'
      'leakage or an ill-fitting restoration.',
  'dentin_hypersensitivity':
  'Exposed dentin layer (from gum recession or enamel wear) makes '
      'the tooth sensitive to thermal and tactile stimuli.',
  'acute_pulpitis':
  'Acute inflammation of the dental pulp. Pain is severe and '
      'persistent, continues after the stimulus ends, and worsens at '
      'night.',
  'chronic_pulpitis':
  'Low-grade chronic inflammation of the pulp. Symptoms are '
      'intermittent and may be completely absent for periods.',
  'pulp_necrosis':
  'Loss of blood supply to the pulp with subsequent necrosis. '
      'May follow acute pulpitis or trauma, and often precedes '
      'abscess formation if untreated.',
  'acute_apical_abscess':
  'Acute bacterial infection at the root apex with pus accumulation. '
      'May spread to the face and become dangerous.',
  'chronic_apical_abscess':
  'Chronic localized infection at the root apex with a fistula for '
      'pus drainage. Less pain, but bone damage continues.',
  'periapical_granuloma':
  'Chronic low-grade inflammation around the root apex without '
      'visible pus. Often discovered incidentally on X-ray.',
  'gingivitis':
  'Superficial gum inflammation from plaque accumulation. Fully '
      'reversible with good hygiene.',
  'periodontitis':
  'Advanced inflammation destroying the bone supporting the tooth. '
      'If untreated, leads to progressive tooth loss.',
  'gingival_recession':
  'Receding gum margin from aggressive brushing, chronic '
      'inflammation, or anatomical factors.',
  'gingival_abscess':
  'Pus collection inside a periodontal pocket. May recur if the '
      'underlying cause (periodontitis) is not treated.',
  'pericoronitis':
  'Inflammation of the gum around a partially impacted wisdom tooth '
      'due to food and bacteria trapping.',
  'aphthous_ulcer':
  'Painful superficial ulcer usually appearing on the lips or inner '
      'cheek. Heals within 7–10 days without scarring.',
  'oral_candidiasis':
  'Fungal infection (Candida) appearing as a white coating. More '
      'common with weak immunity, dry mouth, or after antibiotics.',
  'angular_cheilitis':
  'Inflammation at the corners of the mouth, often fungal, '
      'bacterial, from vitamin B deficiency, or saliva pooling.',
  'tooth_fracture':
  'Partial or complete tooth fracture from trauma or biting a hard '
      'object. May extend to the pulp.',
  'tooth_avulsion':
  'Complete displacement of a tooth from its socket due to trauma. '
      'Time is critical — every minute improves the chance of saving '
      'the tooth.',
  'enamel_hypoplasia':
  'Defect in enamel formation during tooth development, appearing '
      'as discoloration or weakness in the outer layer.',
  'fluorosis':
  'Discoloration from excessive fluoride intake during tooth '
      'development (usually from drinking water). Cosmetic, not '
      'pathological.',
  'impacted_tooth':
  'A tooth that did not erupt on schedule — usually a wisdom tooth '
      'or canine — and may remain inside the bone.',
  'bruxism':
  'Involuntary teeth grinding during sleep or focus, causing '
      'enamel wear and jaw muscle pain.',
  'tmj_disorder':
  'Dysfunction of the temporomandibular joint causing clicking, '
      'pain, and difficulty opening.',
  'dry_socket':
  'Loss of the protective blood clot after extraction, exposing '
      'bone and nerve endings — severe pain.',
};

// ═══════════════════════════════════════════════════════════════
// Recommendations — keyed by stable `condition.key`.
// ═══════════════════════════════════════════════════════════════
const _recommendationEn = <String, String>{
  'dental_caries':
  'See a dentist within days. Early treatment is simple (a filling); '
      'delay may lead to pulp inflammation. Brush twice daily and '
      'reduce sugar intake.',
  'recurrent_caries':
  'See a dentist within days. The filling usually needs replacement '
      'to remove the decay before it reaches the pulp.',
  'dentin_hypersensitivity':
  'Use desensitizing toothpaste and avoid acidic foods and '
      'aggressive brushing. See a dentist if it persists.',
  'acute_pulpitis':
  'See a dentist within 24–48 hours. Usually requires root canal '
      'treatment (pulp removal) to relieve pain and prevent abscess '
      'formation.',
  'chronic_pulpitis':
  'See a dentist within days. Usually requires preventive root canal '
      'treatment to avoid an acute flare-up or abscess.',
  'pulp_necrosis':
  'See a dentist within days. Usually requires root canal treatment '
      'to prevent periapical abscess.',
  'acute_apical_abscess':
  'Go to the emergency room immediately. Requires incision and '
      'drainage or root canal treatment, plus antibiotics. Do not '
      'delay — the infection may spread.',
  'chronic_apical_abscess':
  'See a dentist within days. Usually requires root canal treatment '
      'with antibiotics.',
  'periapical_granuloma':
  'See a dentist within weeks. May require preventive root canal '
      'treatment.',
  'gingivitis':
  'Improve brushing and use dental floss daily. See a dentist for '
      'professional cleaning (scaling).',
  'periodontitis':
  'See a dentist within days. Requires specialized periodontal '
      'treatment (deep cleaning and bone assessment).',
  'gingival_recession':
  'Use a soft toothbrush and correct brushing technique. See a '
      'dentist to evaluate whether a gum graft is needed.',
  'gingival_abscess':
  'See a dentist within 24–48 hours. Requires drainage and pocket '
      'cleaning.',
  'pericoronitis':
  'See a dentist within 24–48 hours. Wisdom tooth extraction is '
      'usually recommended to prevent recurrence.',
  'aphthous_ulcer':
  'Use a mouthwash or soothing gel. Avoid spicy and acidic foods. '
      'See a dentist if it persists beyond two weeks.',
  'oral_candidiasis':
  'See a dentist within days. Requires topical antifungal treatment '
      'and evaluation of the underlying cause.',
  'angular_cheilitis':
  'Use a lip moisturizer. See a dentist if it does not improve '
      'within a week (may need antifungal cream).',
  'tooth_fracture':
  'See a dentist within 24 hours. A wide fracture may need a crown '
      'or root canal. Preserve any broken fragment in milk.',
  'tooth_avulsion':
  'Go to the emergency room immediately. Pick the tooth up by the '
      'crown (not the root), gently reinsert it, or store it in milk '
      '/ saline — never in water.',
  'enamel_hypoplasia':
  'See a dentist for evaluation. May need cosmetic treatment '
      '(composite filling, whitening, or crown).',
  'fluorosis':
  'See a dentist for cosmetic treatment (whitening or veneers) in '
      'severe cases.',
  'impacted_tooth':
  'See a dentist for an X-ray. May require surgical extraction or '
      'orthodontic alignment.',
  'bruxism':
  'See a dentist to have a night guard made. Try relaxation '
      'techniques before sleep.',
  'tmj_disorder':
  'Avoid hard foods and wide mouth opening. Use warm compresses. '
      'See a dentist if it persists.',
  'dry_socket':
  'See a dentist within 24–48 hours. A medicated dressing is needed '
      'in the socket to relieve pain.',
};

// ═══════════════════════════════════════════════════════════════
// Public translators
// ═══════════════════════════════════════════════════════════════

/// Condition name (Arabic from backend → display string).
String translateCondition(String arabic, {required bool isArabic}) {
  if (isArabic || arabic.isEmpty) return arabic;
  return _conditionEn[arabic] ?? arabic;
}

/// Anatomical location.
String translateLocation(String arabic, {required bool isArabic}) {
  if (isArabic || arabic.isEmpty) return arabic;
  return _locationEn[arabic] ?? arabic;
}

/// Severity word (خفيف / متوسط / شديد).
String translateSeverity(String arabic, {required bool isArabic}) {
  if (isArabic || arabic.isEmpty) return arabic;
  return _severityEn[arabic] ?? arabic;
}

/// Urgency enum code (routine / soon / urgent / emergency).
String translateUrgency(String code, {required bool isArabic}) {
  if (isArabic) return _urgencyAr[code] ?? code;
  return _urgencyEn[code] ?? code;
}

/// Patient-reported symptom.
String translateSymptom(String arabic, {required bool isArabic}) {
  if (isArabic || arabic.isEmpty) return arabic;
  return _symptomEn[arabic] ?? arabic;
}

/// A single warning string (may be dynamic — pattern-matched).
String translateWarning(String arabic, {required bool isArabic}) {
  if (isArabic || arabic.isEmpty) return arabic;

  // Pattern: "احتمال قريب بين حالتين: X و Y — راجع طبيباً للتقييم."
  const closeProbPrefix = 'احتمال قريب بين حالتين: ';
  if (arabic.startsWith(closeProbPrefix)) {
    final rest = arabic.substring(closeProbPrefix.length);
    final sepIdx = rest.indexOf(' — ');
    if (sepIdx > 0) {
      final pair = rest.substring(0, sepIdx).split(' و ');
      if (pair.length == 2) {
        final a = translateCondition(pair[0].trim(), isArabic: false);
        final b = translateCondition(pair[1].trim(), isArabic: false);
        return 'Close probability between two conditions: $a and $b — '
            'consult a dentist for evaluation.';
      }
    }
    return 'Close probability between two conditions — '
        'consult a dentist for evaluation.';
  }

  return _warningEn[arabic] ?? arabic;
}

/// Red-flag symptom (e.g. "حمى أو ارتفاع حرارة").
String translateRedFlag(String arabic, {required bool isArabic}) {
  if (isArabic || arabic.isEmpty) return arabic;
  return _redFlagEn[arabic] ?? arabic;
}

/// Emergency instruction line.
String translateEmergencyInstruction(
    String arabic, {
      required bool isArabic,
    }) {
  if (isArabic || arabic.isEmpty) return arabic;
  return _emergencyInstructionEn[arabic] ?? arabic;
}

/// Condition's clinical note.
///
/// Uses the stable condition `key` to look up the English translation;
/// falls back to [fallbackAr] when the key isn't yet translated.
String translateNotes({
  required String key,
  required String fallbackAr,
  required bool isArabic,
}) {
  if (isArabic || fallbackAr.isEmpty) return fallbackAr;
  return _notesEn[key] ?? fallbackAr;
}

/// Condition's recommendation.
///
/// Uses the stable condition `key` to look up the English translation;
/// falls back to [fallbackAr] when the key isn't yet translated.
String translateRecommendation({
  required String key,
  required String fallbackAr,
  required bool isArabic,
}) {
  if (isArabic || fallbackAr.isEmpty) return fallbackAr;
  return _recommendationEn[key] ?? fallbackAr;
}