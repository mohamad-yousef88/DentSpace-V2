"""Temporary smoke test for the symptom analyzer. Delete after use."""
from app.domain.services.symptom_analyzer import (
    analyze_symptoms,
    detect_red_flags,
    SEVERITY_SEVERE,
    SEVERITY_MODERATE,
)


def show(title: str, **kw):
    print("=" * 68)
    print(title)
    print("-" * 68)
    result = analyze_symptoms(**kw)
    print(f"Urgency   : {result.urgency.value}")
    print(f"Red flags : {result.red_flags}")
    print(f"Primary   : {result.primary.name_ar} "
          f"({result.primary.confidence_pct}%)")
    for alt in result.alternatives:
        print(f"  alt     : {alt.name_ar} ({alt.confidence_pct}%)")
    if result.warnings:
        for w in result.warnings:
            print(f"⚠️  {w}")
    if result.emergency_instructions:
        print("Emergency instructions:")
        for line in result.emergency_instructions:
            print(f"  {line}")
    print()


# ── 1. Typical caries
show(
    "Case 1 — caries",
    selected_symptoms=[
        "ثقوب أو تجاويف ظاهرة",
        "حساسية للمشروبات الباردة أوالساخنة",
    ],
    pain_severity=SEVERITY_MODERATE,
    age=30,
    location="الفك العلوي الأيسر",
)

# ── 2. Acute pulpitis (night pain)
show(
    "Case 2 — acute pulpitis",
    selected_symptoms=[
        "ألم نابض",
        "ألم يستمر بعد زوال المؤثر",
        "ألم يوقظ من النوم",
    ],
    pain_severity=SEVERITY_SEVERE,
    age=28,
)

# ── 3. Emergency abscess
show(
    "Case 3 — acute apical abscess",
    selected_symptoms=[
        "ألم نابض",
        "تورم في الوجه أو اللثة",
        "حمى أو ارتفاع حرارة",
    ],
    pain_severity=SEVERITY_SEVERE,
    swelling_severity=SEVERITY_SEVERE,
    age=35,
)

# ── 4. Tooth avulsion (emergency)
show(
    "Case 4 — tooth avulsion",
    selected_symptoms=[
        "انقلاع كامل للسن من مكانه",
        "إصابة أو كسر سن نتيجة رض",
    ],
    age=20,
)

# ── 5. Gingivitis
show(
    "Case 5 — gingivitis",
    selected_symptoms=[
        "نزيف لثوي عند التفريش",
        "احمرار وتورم اللثة",
    ],
    age=25,
)

# ── 6. Pericoronitis (age + location filter)
show(
    "Case 6 — pericoronitis",
    selected_symptoms=[
        "ألم في زاوية الفك الخلفية",
        "تورم اللثة حول السن الأخير",
        "صعوبة في فتح الفم",
    ],
    pain_severity=SEVERITY_MODERATE,
    age=22,
    location="الفك السفلي الأيسر",
)

# ── 7. Bruxism
show(
    "Case 7 — bruxism",
    selected_symptoms=[
        "صرير الأسنان خلال النوم",
        "ألم في عضلات الفك عند الاستيقاظ",
        "صداع صباحي",
    ],
    age=32,
)

# ── 8. Red flags only
flags = detect_red_flags(
    ["تورم ينتشر إلى العين أو الرقبة", "حمى أو ارتفاع حرارة"]
)
print("=" * 68)
print("Case 8 — red flag detection")
print("-" * 68)
print(f"Detected: {flags}")