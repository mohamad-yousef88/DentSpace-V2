"""
Symptom analyzer — advanced dental condition inference.

Algorithm: Weighted Certainty Factors (MYCIN-style)
====================================================

Each condition is a "hypothesis". Each reported symptom contributes
signed evidence to every hypothesis:

    CF ∈ [-1.0, +1.0]
        +1.0  → strongly confirms the condition
         0.0  → no information
        -1.0  → strongly rules the condition out

Evidence is combined using the standard certainty-factor combination
rule (Shortliffe & Buchanan, 1975):

    CF_combined = CF1 + CF2 * (1 - CF1)                 if CF1, CF2 ≥ 0
    CF_combined = CF1 + CF2 * (1 + CF1)                 if CF1, CF2 < 0
    CF_combined = (CF1 + CF2) / (1 - min(|CF1|,|CF2|))  otherwise

Contextual modulation applied after combination:

    • Age         — conditions have preferred age ranges
    • Location    — conditions are anatomically localised
    • Severity    — amplifies conditions whose hallmark is severe pain

Diagnostic principles enforced
------------------------------
1. A condition fires only if the patient reported at least one of its
   positively-weighted symptoms. Severity alone never creates a
   diagnosis — it only amplifies existing evidence.
2. Contradicting symptoms reduce confidence via the CF combination rule.
3. Red flags short-circuit the triage level to EMERGENCY regardless of
   the weighted outcome.
4. Confidence is calibrated in two independent components (evidence
   strength + coverage) so conditions with more symptoms are not
   penalised.
5. Pivotal symptoms gate confidence: absence caps at PIVOTAL_CAP,
   strong presence (cf ≥ 0.9) floors at 0.80.

No I/O. Fully deterministic. Ready for unit tests.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field
from enum import Enum


# ═══════════════════════════════════════════════════════════════
# Enums
# ═══════════════════════════════════════════════════════════════
class Urgency(str, Enum):
    ROUTINE = "routine"          # روتيني — يمكن الانتظار أسبوعاً
    SOON = "soon"                # خلال أيام
    URGENT = "urgent"            # خلال 24–48 ساعة
    EMERGENCY = "emergency"      # فوراً — توجه للطوارئ


class Category(str, Enum):
    CARIES = "caries"
    PULP = "pulp"
    PERIAPICAL = "periapical"
    PERIODONTAL = "periodontal"
    MUCOSAL = "mucosal"
    TRAUMA = "trauma"
    DEVELOPMENTAL = "developmental"
    FUNCTIONAL = "functional"
    OTHER = "other"


# ═══════════════════════════════════════════════════════════════
# Dataclasses
# ═══════════════════════════════════════════════════════════════
@dataclass(frozen=True)
class ConditionProfile:
    """A dental condition hypothesis."""

    key: str
    name_ar: str
    category: Category
    urgency: Urgency
    symptoms: dict[str, float]

    age_min: int | None = None
    age_max: int | None = None
    preferred_locations: tuple[str, ...] = ()

    # Symptoms that MUST be present for high-confidence diagnosis.
    # If none are reported, confidence is capped at PIVOTAL_CAP (0.40).
    pivotal_symptoms: tuple[str, ...] = ()

    # Symptoms that ABSOLUTELY RULE OUT this condition.
    # If any is reported, this condition is discarded entirely.
    contradicted_by: tuple[str, ...] = ()

    notes_ar: str = ""
    recommendation_ar: str = ""


@dataclass(frozen=True)
class DiagnosisMatch:
    key: str
    name_ar: str
    confidence: float                    # 0.0 – 1.0
    category: Category
    urgency: Urgency
    notes_ar: str
    recommendation_ar: str

    @property
    def confidence_pct(self) -> int:
        return int(round(self.confidence * 100))


@dataclass(frozen=True)
class DiagnosisResult:
    """Result returned to the application layer."""

    primary: DiagnosisMatch
    alternatives: list[DiagnosisMatch]
    urgency: Urgency
    red_flags: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    emergency_instructions: list[str] = field(default_factory=list)

    @property
    def is_emergency(self) -> bool:
        return self.urgency == Urgency.EMERGENCY

    @property
    def has_tie(self) -> bool:
        if not self.alternatives:
            return False
        return math.isclose(
            self.primary.confidence,
            self.alternatives[0].confidence,
            abs_tol=0.05,
        )

    @property
    def all_matches(self) -> list[DiagnosisMatch]:
        return [self.primary, *self.alternatives]


# ═══════════════════════════════════════════════════════════════
# Severity keywords
# ═══════════════════════════════════════════════════════════════
SEVERITY_MILD = "خفيف"
SEVERITY_MODERATE = "متوسط"
SEVERITY_SEVERE = "شديد"

SEVERITY_TO_LEVEL: dict[str, float] = {
    SEVERITY_MILD: 3.0,
    SEVERITY_MODERATE: 6.0,
    SEVERITY_SEVERE: 9.0,
}
LEVEL_TO_SEVERITY: dict[float, str] = {v: k for k, v in SEVERITY_TO_LEVEL.items()}
PIVOTAL_CAP = 0.40


# ═══════════════════════════════════════════════════════════════
# Red flags — evaluated before scoring
# ═══════════════════════════════════════════════════════════════
RED_FLAGS: dict[str, str] = {
    "تورم ينتشر إلى العين أو الرقبة":
        "تورم خطير قد يهدد المجرى التنفسي",
    "صعوبة في البلع أو التنفس":
        "علامة خطر — توجه للطوارئ فوراً",
    "حمى أو ارتفاع حرارة":
        "قد يشير إلى عدوى جهازية تحتاج علاجاً عاجلاً",
    "نزيف فموي غزير لا يتوقف":
        "قد يحتاج إسعافاً فورياً",
    "إصابة أو كسر سن نتيجة رض":
        "علاج فوري قد ينقذ السن",
    "ألم لا يزول بالمسكنات":
        "قد يشير إلى عدوى أو التهاب شديد",
    "تورم يغلق العين":
        "خراج منتشر — طارئ",
    "انقلاع كامل للسن من مكانه":
        "أعد السن إلى مكانه أو احفظه في حليب/محلول ملحي وتوجه للطوارئ فوراً",
}


# ═══════════════════════════════════════════════════════════════
# General emergency instructions (attached when triage = EMERGENCY)
# ═══════════════════════════════════════════════════════════════
EMERGENCY_INSTRUCTIONS: tuple[str, ...] = (
    "توجه إلى أقرب قسم طوارئ أسنان فوراً.",
    "إن كان هناك تورم في الوجه، ضع كمادات باردة من الخارج.",
    "تجنب استعمال الحرارة الموضعية على الوجه.",
    "يمكنك تناول مسكن ألم متاح (مثل الباراسيتامول) مؤقتاً.",
    "لا تحاول فتح الخراج بنفسك.",
    "اصطحب معك أي تقارير طبية أو صور أشعة إن كانت متوفرة.",
)


# ═══════════════════════════════════════════════════════════════
# Symptom catalogue — 25 well-characterised conditions
# ═══════════════════════════════════════════════════════════════
# Weight reference:
#    +0.9  → pathognomonic (nearly unique to this condition)
#    +0.6  → highly suggestive
#    +0.4  → moderately suggestive
#    +0.2  → weakly suggestive
#    -0.2  → mildly contradictory
#    -0.3  → strongly contradictory
# ═══════════════════════════════════════════════════════════════
CONDITIONS: tuple[ConditionProfile, ...] = (

    # ═══ CARIES family ═══════════════════════════════════════
    ConditionProfile(
        key="dental_caries",
        name_ar="تسوس الأسنان",
        category=Category.CARIES,
        urgency=Urgency.SOON,
        age_min=6, age_max=60,
        symptoms={
            "ثقوب أو تجاويف ظاهرة": 0.9,
            "تصبغات داكنة على السن": 0.7,
            "ألم عند تناول الحلويات": 0.6,
            "حساسية للمشروبات الباردة أوالساخنة": 0.4,
            "ألم في مكان النخر": 0.4,
            "رائحة كريهة للفم": 0.2,
            "ألم عند المضغ": 0.2,
        },
        notes_ar=(
            "تآكل تدريجي في مينا السن بسبب أحماض تنتجها البكتيريا "
            "عند تحلل السكريات. يبدأ صامتاً ثم يسبب حساسية وألماً."
        ),
        recommendation_ar=(
            "راجع طبيب الأسنان خلال أيام. العلاج المبكر بسيط (حشوة)، "
            "أما التأخير فقد يؤدي لالتهاب العصب. "
            "نظّف أسنانك مرتين يومياً وقلّل السكريات."
        ),
    ),

    ConditionProfile(
        key="recurrent_caries",
        name_ar="تسوس ثانوي تحت حشوة",
        category=Category.CARIES,
        urgency=Urgency.SOON,
        symptoms={
            "تسوس تحت حشوة قديمة": 0.9,
            "تصبغات داكنة حول حشوة": 0.7,
            "ألم عند مضغ الأطعمة الصلبة": 0.4,
            "حساسية للمشروبات الباردة أوالساخنة": 0.3,
            "رائحة كريهة للفم": 0.2,
        },
        notes_ar=(
            "تسوس جديد يتكوّن عند حواف حشوة قديمة بسبب تسرّب "
            "دقيق أو عدم إحكام الحشوة."
        ),
        recommendation_ar=(
            "راجع الطبيب خلال أيام. غالباً تحتاج الحشوة إلى استبدال "
            "لإزالة التسوس قبل أن يصل إلى العصب."
        ),
    ),

    ConditionProfile(
        key="dentin_hypersensitivity",
        name_ar="حساسية الأسنان",
        category=Category.CARIES,
        urgency=Urgency.ROUTINE,
        symptoms={
            "ألم حاد لحظي عند التعرض للمنبهات": 0.7,
            "حساسية للمشروبات الباردة أوالساخنة": 0.5,
            "انحسار اللثة": 0.4,
            "تصبغات بيضاء أو بنية": 0.2,
            "ألم في مكان النخر": -0.3,
            "ثقوب أو تجاويف ظاهرة": -0.2,
        },
        notes_ar=(
            "انكشاف طبقة العاج بسبب تراجع اللثة أو تآكل المينا يجعل "
            "السن حساساً للمنبهات الحرارية واللمسية."
        ),
        recommendation_ar=(
            "استخدم معجوناً مخصصاً للحساسية وتجنّب الأحماض "
            "والتفريش العنيف. راجع الطبيب إن استمر الأمر."
        ),
    ),

    # ═══ PULP family ═════════════════════════════════════════
    ConditionProfile(
        key="acute_pulpitis",
        name_ar="التهاب لب السن الحاد",
        category=Category.PULP,
        urgency=Urgency.URGENT,
        symptoms={
            "ألم نابض": 0.8,
            "ألم يستمر بعد زوال المؤثر": 0.7,
            "ألم ليلي يمنع النوم": 0.7,
            "ألم يوقظ من النوم": 0.6,
            "حساسية للمشروبات الباردة أوالساخنة": 0.4,
            "وخز في المنطقة المحيطة بالسن": 0.3,
            "ألم عند المضغ": 0.3,
        },
        notes_ar=(
            "التهاب حاد في عصب السن. الألم شديد ومستمر، ويستمر "
            "بعد زوال المؤثر، ويزداد ليلاً."
        ),
        recommendation_ar=(
            "راجع طبيب الأسنان خلال 24–48 ساعة. غالباً يحتاج علاج عصب "
            "(سحب اللب) لإزالة الألم ومنع تكوّن الخراج."
        ),
    ),

    ConditionProfile(
        key="chronic_pulpitis",
        name_ar="التهاب لب السن المزمن",
        category=Category.PULP,
        urgency=Urgency.SOON,
        symptoms={
            "حساسية للمشروبات الباردة أوالساخنة": 0.5,
            "ألم خفيف يظهر ويختفي": 0.5,
            "ألم عند المضغ": 0.4,
            "ألم يستمر بعد زوال المؤثر": 0.3,
            "تصبغات داكنة على السن": 0.3,
            "ألم نابض": -0.2,
        },
        notes_ar=(
            "التهاب مزمن منخفض الشدة في عصب السن. الأعراض متقطعة "
            "وقد تكون غائبة تماماً في بعض الفترات."
        ),
        recommendation_ar=(
            "راجع الطبيب خلال أيام. غالباً يحتاج علاج عصب وقائي "
            "لتجنّب تحوّله إلى التهاب حاد أو خراج."
        ),
    ),

    ConditionProfile(
        key="pulp_necrosis",
        name_ar="موت لب السن (نخر)",
        category=Category.PULP,
        urgency=Urgency.SOON,
        symptoms={
            "تغير لون السن إلى رمادي أو داكن": 0.8,
            "ألم سابق اختفى فجأة": 0.6,
            "تصبغات داكنة على السن": 0.4,
            "ألم عند المضغ": 0.3,
            "حساسية للمشروبات الباردة أوالساخنة": -0.3,
            "ألم نابض": -0.2,
        },
        notes_ar=(
            "توقف تروية العصب وموته. قد يحدث بعد التهاب حاد أو رضّ، "
            "وغالباً يسبق تكوّن خراج إذا لم يُعالج."
        ),
        recommendation_ar=(
            "راجع الطبيب خلال أيام. غالباً يحتاج علاج عصب لتجنّب "
            "تكوّن خراج حول الجذر."
        ),
    ),

    # ═══ PERIAPICAL family ═══════════════════════════════════
    ConditionProfile(
        key="acute_apical_abscess",
        name_ar="خراج حول الذروة الحاد",
        category=Category.PERIAPICAL,
        urgency=Urgency.EMERGENCY,
        symptoms={
            "تورم في الوجه أو اللثة": 0.9,
            "ألم نابض": 0.7,
            "السن يبدو أطول من جيرانه": 0.6,
            "ألم شديد عند المضغ": 0.6,
            "ألم يوقظ من النوم": 0.5,
            "طعم كريه في الفم": 0.4,
            "حمى أو ارتفاع حرارة": 0.4,
            "السن المتحرك قليلاً": 0.3,
        },
        # ★ Pivotal — the hallmark signs of an acute apical abscess.
        # Without at least ONE of these, confidence is capped at 0.40.
        pivotal_symptoms=(
            "تورم في الوجه أو اللثة",
            "ألم شديد عند المضغ",
            "السن يبدو أطول من جيرانه",
        ),
        notes_ar=(
            "عدوى بكتيرية حادة في نهاية جذر السن مع تجمّع قيح. "
            "قد ينتشر إلى الوجه ويصبح خطراً."
        ),
        recommendation_ar=(
            "توجه للطوارئ فوراً. يحتاج فتحاً وتصريفاً للقيح أو علاج عصب، "
            "مع مضاد حيوي. لا تتأخر — العدوى قد تنتشر."
        ),
    ),

    ConditionProfile(
        key="chronic_apical_abscess",
        name_ar="خراج حول الذروة المزمن",
        category=Category.PERIAPICAL,
        urgency=Urgency.SOON,
        symptoms={
            "ناسور فموي (فتحة صغيرة تخرج منها سوائل)": 0.9,
            "طعم كريه في الفم": 0.5,
            "تورم صغير ثابت على اللثة": 0.5,
            "ألم خفيف عند المضغ": 0.4,
            "حمى أو ارتفاع حرارة": -0.3,
        },
        # The fistula (ناسور) is itself pathognomonic, so no
        # additional pivotal gating is required here.
        notes_ar=(
            "عدوى مزمنة متحوصلة في نهاية الجذر مع ناسور لتصريف القيح. "
            "الألم أقل لكن الضرر على العظم يستمر."
        ),
        recommendation_ar=(
            "راجع الطبيب خلال أيام. غالباً يحتاج علاج عصب مع مضاد حيوي."
        ),
    ),

    ConditionProfile(
        key="periapical_granuloma",
        name_ar="ورم حبيبي حول الذروة",
        category=Category.PERIAPICAL,
        urgency=Urgency.ROUTINE,
        symptoms={
            "التهاب متكرر في نفس المنطقة": 0.5,
            "ألم خفيف مستمر": 0.4,
            "انتفاخ بسيط في اللثة": 0.4,
            "ألم عند المضغ": 0.3,
        },
        notes_ar=(
            "التهاب مزمن منخفض الشدة حول قمة الجذر بدون قيح ظاهر. "
            "غالباً يُكتشف بالصدفة عبر الأشعة."
        ),
        recommendation_ar=(
            "راجع الطبيب خلال أسابيع. قد يحتاج علاج عصب وقائي."
        ),
    ),

    # ═══ PERIODONTAL family ══════════════════════════════════
    ConditionProfile(
        key="gingivitis",
        name_ar="التهاب اللثة",
        category=Category.PERIODONTAL,
        urgency=Urgency.ROUTINE,
        symptoms={
            "نزيف لثوي عند التفريش": 0.8,
            "احمرار وتورم اللثة": 0.7,
            "رائحة كريهة للفم": 0.4,
            "ألم أو حكة في اللثة": 0.4,
            "انحسار اللثة": 0.2,
        },
        notes_ar=(
            "التهاب سطحي في اللثة بسبب تراكم البلاك. قابل للعلاج "
            "والشفاء الكامل بالتنظيف الجيد."
        ),
        recommendation_ar=(
            "حسّن تفريش الأسنان واستخدم الخيط الطبي يومياً. "
            "راجع الطبيب لتنظيف اللثة (تقليح)."
        ),
    ),

    ConditionProfile(
        key="periodontitis",
        name_ar="التهاب دواعم السن",
        category=Category.PERIODONTAL,
        urgency=Urgency.SOON,
        symptoms={
            "اهتزاز السن": 0.8,
            "انحسار اللثة": 0.6,
            "خروج قيح من بين الأسنان": 0.5,
            "نزيف لثوي": 0.5,
            "رائحة كريهة للفم": 0.5,
            "طعم سيء أو إقياء": 0.4,
            "ألم عند المضغ": 0.3,
        },
        notes_ar=(
            "التهاب متقدم يدمر العظم الداعم للسن. إذا لم يُعالج يؤدي "
            "إلى فقدان الأسنان تدريجياً."
        ),
        recommendation_ar=(
            "راجع طبيب الأسنان خلال أيام. يحتاج علاج لثة متخصص "
            "(تنظيف عميق + تقييم العظم)."
        ),
    ),

    ConditionProfile(
        key="gingival_recession",
        name_ar="تراجع اللثة",
        category=Category.PERIODONTAL,
        urgency=Urgency.ROUTINE,
        symptoms={
            "انحسار اللثة": 0.9,
            "السن يبدو أطول من المعتاد": 0.6,
            "حساسية للمشروبات الباردة أوالساخنة": 0.4,
            "ألم أو حكة في اللثة": 0.3,
        },
        notes_ar=(
            "تراجع حافة اللثة عن مينا السن نتيجة تفريش عنيف، "
            "أو التهاب مزمن، أو أسباب تشريحية."
        ),
        recommendation_ar=(
            "استخدم فرشاة ناعمة وتقنية تفريش صحيحة. "
            "راجع الطبيب لتقييم الحاجة لترقيع لثوي."
        ),
    ),

    ConditionProfile(
        key="gingival_abscess",
        name_ar="خراج لثوي",
        category=Category.PERIODONTAL,
        urgency=Urgency.URGENT,
        symptoms={
            "تورم أحمر مؤلم على اللثة": 0.8,
            "ألم نابض في اللثة": 0.7,
            "خروج قيح من بين الأسنان": 0.5,
            "احمرار وتورم اللثة": 0.4,
        },
        notes_ar=(
            "تجمّع قيح داخل جيب لثوي. يمكن أن يتكرر إذا لم يُعالج "
            "السبب الأساسي (التهاب دواعم)."
        ),
        recommendation_ar=(
            "راجع الطبيب خلال 24–48 ساعة. يحتاج تصريفاً وتنظيفاً "
            "للجيب اللثوي."
        ),
    ),

    ConditionProfile(
        key="pericoronitis",
        name_ar="التهاب حوائط التاج (ضرس العقل)",
        category=Category.PERIODONTAL,
        urgency=Urgency.URGENT,
        age_min=16, age_max=35,
        preferred_locations=("الفك السفلي الأيسر", "الفك السفلي الأيمن"),
        symptoms={
            "ألم في زاوية الفك الخلفية": 0.8,
            "تورم اللثة حول السن الأخير": 0.7,
            "صعوبة في فتح الفم": 0.7,
            "ألم عند البلع": 0.5,
            "رائحة كريهة للفم": 0.3,
            "حمى أو ارتفاع حرارة": 0.3,
        },
        notes_ar=(
            "التهاب في اللثة المحيطة بضرس العقل المدفون جزئياً "
            "نتيجة احتباس الطعام والبكتيريا."
        ),
        recommendation_ar=(
            "راجع الطبيب خلال 24–48 ساعة. غالباً يُنصح بخلع ضرس العقل "
            "لمنع التكرار."
        ),
    ),

    # ═══ MUCOSAL family ══════════════════════════════════════
    ConditionProfile(
        key="aphthous_ulcer",
        name_ar="قرحة فموية (قوباء)",
        category=Category.MUCOSAL,
        urgency=Urgency.ROUTINE,
        symptoms={
            "تقرح صغير مؤلم": 0.9,
            "حرقة عند الأكل أو الشرب": 0.5,
            "التهاب موضعي في الفم": 0.3,
        },
        notes_ar=(
            "قرحة سطحية مؤلمة تظهر عادة على الشفاه أو الخد من الداخل. "
            "تشفى خلال 7–10 أيام بدون أثر."
        ),
        recommendation_ar=(
            "استخدم غسولاً للفم أو جل مهدئ. تجنب الأطعمة الحارة "
            "والحمضية. راجع الطبيب إن استمرت أكثر من أسبوعين."
        ),
    ),

    ConditionProfile(
        key="oral_candidiasis",
        name_ar="السلاق الفموي (فطري)",
        category=Category.MUCOSAL,
        urgency=Urgency.SOON,
        symptoms={
            "طبقة بيضاء قابلة للإزالة على اللسان أو الخد": 0.9,
            "حرقة في الفم": 0.5,
            "طعم غير طبيعي في الفم": 0.4,
            "احمرار تحت الطبقة البيضاء": 0.4,
        },
        notes_ar=(
            "عدوى فطرية (Candida) تظهر كطبقة بيضاء. أكثر شيوعاً عند "
            "ضعف المناعة، جفاف الفم، أو بعد المضادات الحيوية."
        ),
        recommendation_ar=(
            "راجع الطبيب خلال أيام. يحتاج مضاداً فطرياً موضعياً "
            "وتقييماً للسبب الكامن."
        ),
    ),

    ConditionProfile(
        key="angular_cheilitis",
        name_ar="تشقق زوايا الفم",
        category=Category.MUCOSAL,
        urgency=Urgency.ROUTINE,
        symptoms={
            "تشقق في زوايا الفم": 0.9,
            "ألم عند فتح الفم": 0.6,
            "قشور في زوايا الشفاه": 0.5,
            "احمرار زوايا الفم": 0.5,
        },
        notes_ar=(
            "التهاب في زوايا الفم، غالباً بسبب فطري أو بكتيري أو نقص "
            "فيتامين B، أو تراكم اللعاب."
        ),
        recommendation_ar=(
            "استخدم مرطباً للشفاه. راجع الطبيب إن لم يتحسن خلال أسبوع "
            "(قد يحتاج كريماً مضاداً للفطريات)."
        ),
    ),

    # ═══ TRAUMA family ═══════════════════════════════════════
    ConditionProfile(
        key="tooth_fracture",
        name_ar="كسر السن",
        category=Category.TRAUMA,
        urgency=Urgency.URGENT,
        symptoms={
            "إصابة أو كسر سن نتيجة رض": 0.9,
            "جزء من السن مفقود": 0.8,
            "ألم حاد عند العض": 0.6,
            "حساسية للمشروبات الباردة أوالساخنة": 0.4,
        },
        pivotal_symptoms=(
            "جزء من السن مفقود",
            "إصابة أو كسر سن نتيجة رض",
        ),
        contradicted_by=(
            "انقلاع كامل للسن من مكانه",
        ),
        notes_ar=(
            "كسر جزئي أو كلي في السن بسبب رضّ أو عضّ شيء صلب. "
            "قد يصل الكسر إلى العصب."
        ),
        recommendation_ar=(
            "راجع الطبيب خلال 24 ساعة. إن كان الكسر واسعاً قد يحتاج "
            "تاجاً أو علاج عصب. احفظ أي قطعة مكسورة في حليب."
        ),
    ),

    ConditionProfile(
        key="tooth_avulsion",
        name_ar="انقلاع كامل للسن",
        category=Category.TRAUMA,
        urgency=Urgency.EMERGENCY,
        symptoms={
            "انقلاع كامل للسن من مكانه": 0.95,
            "نزيف من مكان السن": 0.7,
            "إصابة رض مباشرة": 0.6,
            "ألم شديد في المنطقة": 0.5,
        },
        pivotal_symptoms=(
            "انقلاع كامل للسن من مكانه",
        ),
        contradicted_by=(
            "جزء من السن مفقود",
        ),
        notes_ar=(
            "خروج السن كاملاً من مكانه نتيجة رضّ. الوقت عامل حاسم — "
            "كل دقيقة تزيد فرصة إنقاذ السن."
        ),
        recommendation_ar=(
            "توجه للطوارئ فوراً. التقط السن من التاج (لا من الجذر)، "
            "أعد وضعه بلطف أو احفظه في حليب/محلول ملحي — لا في الماء."
        ),
    ),

    # ═══ DEVELOPMENTAL family ════════════════════════════════
    ConditionProfile(
        key="enamel_hypoplasia",
        name_ar="نقص تَمَعْدُن المينا",
        category=Category.DEVELOPMENTAL,
        urgency=Urgency.ROUTINE,
        symptoms={
            "تصبغات بيضاء أو بنية": 0.9,
            "ضعف في المينا": 0.6,
            "خشونة سطح السن": 0.4,
            "حساسية للمشروبات الباردة أوالساخنة": 0.3,
        },
        notes_ar=(
            "خلل في تكوين المينا أثناء نمو السن، يظهر كتصبغات "
            "أو ضعف في الطبقة الخارجية."
        ),
        recommendation_ar=(
            "راجع الطبيب للتقييم. قد يحتاج علاجاً تجميلياً "
            "(حشوة تجميلية، تبييض، أو تاج)."
        ),
    ),

    ConditionProfile(
        key="fluorosis",
        name_ar="تبقّع الفلورايد",
        category=Category.DEVELOPMENTAL,
        urgency=Urgency.ROUTINE,
        age_min=6, age_max=30,
        symptoms={
            "بقع بيضاء أو بنية على أكثر من سن": 0.9,
            "تصبغات متماثلة على أسنان متقابلة": 0.7,
            "تفتت المينا في الحالات الشديدة": 0.4,
            "خشونة سطح السن": 0.3,
        },
        notes_ar=(
            "تصبغات ناتجة عن تناول فلورايد زائد أثناء نمو السن "
            "(عادة من مياه الشرب). لا يسبب مرضاً لكنه تجميلي."
        ),
        recommendation_ar=(
            "راجع الطبيب للعلاج التجميلي (تبييض أو تلبيس) في "
            "الحالات الشديدة."
        ),
    ),

    ConditionProfile(
        key="impacted_tooth",
        name_ar="سن مدفون",
        category=Category.DEVELOPMENTAL,
        urgency=Urgency.SOON,
        age_min=15, age_max=40,
        symptoms={
            "فقدان سن دائم من الصف بدون خلع سابق": 0.7,
            "انتفاخ اللثة خلف الأسنان": 0.6,
            "ألم في منطقة السن الأخير": 0.5,
            "صعوبة في فتح الفم": 0.4,
        },
        notes_ar=(
            "سن لم يبزغ في موعده، عادة ضرس العقل أو الناب، "
            "وقد يبقى داخل العظم."
        ),
        recommendation_ar=(
            "راجع الطبيب لأخذ صورة أشعة. قد يحتاج خلعاً جراحياً "
            "أو تقويماً لإعادته للصف."
        ),
    ),

    # ═══ FUNCTIONAL family ═══════════════════════════════════
    ConditionProfile(
        key="bruxism",
        name_ar="صرير الأسنان",
        category=Category.FUNCTIONAL,
        urgency=Urgency.ROUTINE,
        symptoms={
            "صرير الأسنان خلال النوم": 0.9,
            "ألم في عضلات الفك عند الاستيقاظ": 0.6,
            "تآكل سطح الأسنان": 0.5,
            "صداع صباحي": 0.5,
            "حساسية للمشروبات الباردة أوالساخنة": 0.3,
        },
        notes_ar=(
            "صرير لا إرادي للأسنان خلال النوم أو التركيز، "
            "يسبب تآكل الأسنان وألم عضلات الفك."
        ),
        recommendation_ar=(
            "راجع الطبيب لصنع واقٍ ليلي. جرّب تقنيات الاسترخاء قبل النوم."
        ),
    ),

    ConditionProfile(
        key="tmj_disorder",
        name_ar="اضطراب مفصل الفك",
        category=Category.FUNCTIONAL,
        urgency=Urgency.SOON,
        symptoms={
            "طقطقة أو صوت عند فتح الفم": 0.8,
            "ألم أمام الأذن": 0.7,
            "صعوبة في فتح الفم": 0.5,
            "صداع قوي": 0.4,
            "ألم عند المضغ": 0.3,
        },
        notes_ar=(
            "خلل في مفصل الفك الصدغي يسبب طقطقة، ألماً، "
            "وصعوبة في الفتح."
        ),
        recommendation_ar=(
            "تجنب الأطعمة الصلبة وفتح الفم واسعاً. استخدم كمادات دافئة. "
            "راجع الطبيب إن استمر."
        ),
    ),

    # ═══ OTHER ═══════════════════════════════════════════════
    ConditionProfile(
        key="dry_socket",
        name_ar="السنخ الجاف (بعد الخلع)",
        category=Category.OTHER,
        urgency=Urgency.URGENT,
        symptoms={
            "ألم شديد بعد خلع السن بـ 2–3 أيام": 0.9,
            "رؤية عظم مكشوف في مكان الخلع": 0.8,
            "رائحة كريهة من مكان الخلع": 0.6,
            "طعم سيء في الفم": 0.5,
        },
        pivotal_symptoms=(
            "رؤية عظم مكشوف في مكان الخلع",
            "ألم شديد بعد خلع السن بـ 2–3 أيام",
        ),
        notes_ar=(
            "فقدان الخثرة الدموية الواقية بعد الخلع، ما يكشف العظم "
            "والنهايات العصبية — ألم شديد."
        ),
        recommendation_ar=(
            "راجع طبيب الأسنان خلال 24–48 ساعة. يحتاج وضع حشوة "
            "طبية في السنخ لتخفيف الألم."
        ),
    ),
)

# Index for O(1) key lookup
CONDITIONS_BY_KEY: dict[str, ConditionProfile] = {c.key: c for c in CONDITIONS}


# ═══════════════════════════════════════════════════════════════
# Certainty-factor combination (Shortliffe & Buchanan, 1975)
# ═══════════════════════════════════════════════════════════════
def combine_cfs(cf1: float, cf2: float) -> float:
    """Combine two certainty factors using the standard CF formula."""
    if cf1 >= 0 and cf2 >= 0:
        return cf1 + cf2 * (1 - cf1)
    if cf1 < 0 and cf2 < 0:
        return cf1 + cf2 * (1 + cf1)
    denom = 1 - min(abs(cf1), abs(cf2))
    if denom == 0:
        return 0.0
    return (cf1 + cf2) / denom


def _combine_all(values: list[float]) -> float:
    """Combine a list of certainty factors (0.0 if empty)."""
    if not values:
        return 0.0
    result = values[0]
    for v in values[1:]:
        result = combine_cfs(result, v)
    return result


# ═══════════════════════════════════════════════════════════════
# Contextual modulation
# ═══════════════════════════════════════════════════════════════
def _age_factor(profile: ConditionProfile, age: int | None) -> float:
    """Multiplicative factor on the CF from age."""
    if age is None or (profile.age_min is None and profile.age_max is None):
        return 1.0
    lo = profile.age_min if profile.age_min is not None else 0
    hi = profile.age_max if profile.age_max is not None else 200
    if lo <= age <= hi:
        return 1.0
    distance = min(abs(age - lo), abs(age - hi))
    return max(0.6, 1.0 - distance * 0.02)


def _location_factor(profile: ConditionProfile, location: str | None) -> float:
    """Multiplicative factor on the CF from anatomical location."""
    if not profile.preferred_locations or not location:
        return 1.0
    return 1.0 if location in profile.preferred_locations else 0.7


def _severity_factor(
    profile: ConditionProfile,
    pain_severity: str | None,
    swelling_severity: str | None,
) -> float:
    """
    Amplify conditions whose urgency matches the reported severity.

    Only conditions in the URGENT/EMERGENCY tiers benefit from severe
    pain or swelling — otherwise the signal is noise.
    """
    boost = 1.0
    if pain_severity == SEVERITY_SEVERE and profile.urgency in (
        Urgency.URGENT, Urgency.EMERGENCY,
    ):
        boost *= 1.15
    if swelling_severity == SEVERITY_SEVERE and profile.urgency in (
        Urgency.URGENT, Urgency.EMERGENCY,
    ):
        boost *= 1.10
    return min(boost, 1.4)


# ═══════════════════════════════════════════════════════════════
# Confidence calibration
# ═══════════════════════════════════════════════════════════════
def _compute_confidence(
    raw_cf: float,
    positive_matches: int,
    negative_matches: int,
    reported_count: int,
    best_pivotal_cf: float | None,
    requires_pivotal: bool,
) -> float:
    """
    Calibrated confidence in [0.0, 1.0].

    Pivotal gating:
      • If a condition requires pivotal symptoms and NONE was reported →
        cap at PIVOTAL_CAP (0.40).
      • If the strongest pivotal symptom has cf ≥ 0.9 → floor 0.80.
      • cf ≥ 0.7 → floor 0.65.
    """
    if raw_cf <= 0 or reported_count <= 0:
        return 0.0

    base = raw_cf / (raw_cf + 0.8)
    effective_matches = max(0.0, positive_matches - 0.5 * negative_matches)
    coverage = effective_matches / reported_count
    confidence = 0.7 * base + 0.3 * coverage

    if negative_matches > 0:
        penalty = 1.0 - min(0.4, negative_matches * 0.15)
        confidence *= penalty

    if requires_pivotal:
        if best_pivotal_cf is None:
            confidence = min(confidence, PIVOTAL_CAP)
        elif best_pivotal_cf >= 0.9:
            confidence = max(confidence, 0.80)
        elif best_pivotal_cf >= 0.7:
            confidence = max(confidence, 0.65)

    return round(min(0.98, max(0.0, confidence)), 4)


# ═══════════════════════════════════════════════════════════════
# Red-flag detection
# ═══════════════════════════════════════════════════════════════
def detect_red_flags(selected_symptoms: list[str]) -> list[str]:
    """Return the list of red-flag labels present in the symptoms."""
    selected = set(selected_symptoms)
    return [flag for flag in RED_FLAGS if flag in selected]


# ═══════════════════════════════════════════════════════════════
# Public API
# ═══════════════════════════════════════════════════════════════
def analyze_symptoms(
    selected_symptoms: list[str],
    *,
    pain_severity: str | None = None,
    swelling_severity: str | None = None,
    age: int | None = None,
    location: str | None = None,
    top_n: int = 3,
    urgent_alternative_threshold: float = 0.45,
) -> DiagnosisResult:
    """
    Return a differential diagnosis for the given clinical input.

    Parameters
    ----------
    selected_symptoms : Arabic symptom labels chosen by the patient.
    pain_severity     : "خفيف" | "متوسط" | "شديد" | None
    swelling_severity : same as pain_severity.
    age               : patient age in years (optional).
    location          : anatomical location string (optional).
    top_n             : how many matches to return (default 3).
    urgent_alternative_threshold :
        Minimum confidence an alternative must have to raise the overall
        triage urgency (policy 1c).

    Returns
    -------
    DiagnosisResult

    Raises
    ------
    ValueError
        If no known condition matches the given symptoms.
    """
    if not selected_symptoms:
        raise ValueError("At least one symptom must be provided.")

    selected = set(selected_symptoms)
    reported_count = len(selected)
    red_flags = detect_red_flags(selected_symptoms)

    matches: list[DiagnosisMatch] = []

    for profile in CONDITIONS:
        # Mutual exclusion — contradicted conditions are skipped entirely.
        if profile.contradicted_by and any(
            c in selected for c in profile.contradicted_by
        ):
            continue

        symptom_cfs: list[float] = []
        positive_matches = 0
        negative_matches = 0

        for symptom in selected:
            w = profile.symptoms.get(symptom)
            if w is None:
                continue
            symptom_cfs.append(w)
            if w > 0:
                positive_matches += 1
            elif w < 0:
                negative_matches += 1

        # A condition must have at least one positively-weighted match.
        if positive_matches == 0:
            continue

        combined_cf = _combine_all(symptom_cfs)
        if combined_cf <= 0:
            continue

        combined_cf *= _age_factor(profile, age)
        combined_cf *= _location_factor(profile, location)
        combined_cf *= _severity_factor(profile, pain_severity, swelling_severity)

        # Pivotal analysis — find the strongest pivotal CF reported
        requires_pivotal = bool(profile.pivotal_symptoms)
        best_pivotal_cf: float | None = None
        if requires_pivotal:
            for p in profile.pivotal_symptoms:
                if p in selected:
                    cf = profile.symptoms.get(p, 0.0)
                    if best_pivotal_cf is None or cf > best_pivotal_cf:
                        best_pivotal_cf = cf

        confidence = _compute_confidence(
            combined_cf,
            positive_matches,
            negative_matches,
            reported_count,
            best_pivotal_cf,
            requires_pivotal,
        )
        if confidence <= 0.0:
            continue

        matches.append(
            DiagnosisMatch(
                key=profile.key,
                name_ar=profile.name_ar,
                confidence=confidence,
                category=profile.category,
                urgency=profile.urgency,
                notes_ar=profile.notes_ar,
                recommendation_ar=profile.recommendation_ar,
            )
        )

    if not matches:
        raise ValueError(
            "لا يمكن تحديد الحالة — لم تُطابق الأعراض أي حالة معروفة. "
            "يُنصح بمراجعة طبيب أسنان لتقييم مباشر."
        )

    matches.sort(key=lambda m: m.confidence, reverse=True)
    matches = matches[:top_n]

    primary = matches[0]
    alternatives = matches[1:]

    # ─── Triage urgency (policy 1c, refined) ───────────────
    # Escalate based on an alternative ONLY when that alternative is
    # genuinely close to the primary (within 10 percentage points).
    # This prevents a distant "worst case" alternative from
    # unnecessarily alarming the patient.
    urgency_rank = {
        Urgency.ROUTINE: 0,
        Urgency.SOON: 1,
        Urgency.URGENT: 2,
        Urgency.EMERGENCY: 3,
    }
    if red_flags:
        urgency = Urgency.EMERGENCY
    else:
        candidate_urgencies = [primary.urgency]
        for alt in alternatives:
            is_strong = alt.confidence >= urgent_alternative_threshold
            is_close = alt.confidence >= primary.confidence - 0.10
            if is_strong and is_close:
                candidate_urgencies.append(alt.urgency)
        urgency = max(candidate_urgencies, key=lambda u: urgency_rank[u])

    # ─── Emergency instructions ────────────────────────────
    emergency_instructions: list[str] = []
    if urgency == Urgency.EMERGENCY:
        emergency_instructions = list(EMERGENCY_INSTRUCTIONS)

    # ─── Warnings ──────────────────────────────────────────
    warnings: list[str] = []
    if alternatives and math.isclose(
        primary.confidence, alternatives[0].confidence, abs_tol=0.05
    ):
        warnings.append(
            f"احتمال قريب بين حالتين: {primary.name_ar} و "
            f"{alternatives[0].name_ar} — راجع طبيباً للتقييم."
        )
    if primary.confidence < 0.55:
        warnings.append(
            "الثقة في التشخيص متوسطة — يُنصح بمتابعة طبية لتقييم أدق."
        )
    if red_flags:
        warnings.append(
            "لديك علامات تحذيرية تستدعي التوجه للطوارئ فوراً — "
            "لا تنتظر موعداً عادياً."
        )

    return DiagnosisResult(
        primary=primary,
        alternatives=alternatives,
        urgency=urgency,
        red_flags=red_flags,
        warnings=warnings,
        emergency_instructions=emergency_instructions,
    )