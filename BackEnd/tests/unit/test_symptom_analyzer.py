"""
Unit tests for the dental symptom analyzer.

Covers:
  • Differential diagnosis (top-3 ranking)
  • Certainty-factor combination
  • Contextual modulation (age, location, severity)
  • Pivotal symptoms (cap + floor)
  • Contradicted-by (mutual exclusion)
  • Red-flag emergency override
  • Tie detection + warnings
  • Robustness (empty input, no matches)
"""
import math

import pytest

from app.domain.services.symptom_analyzer import (
    CONDITIONS,
    EMERGENCY_INSTRUCTIONS,
    PIVOTAL_CAP,
    SEVERITY_MILD,
    SEVERITY_MODERATE,
    SEVERITY_SEVERE,
    Urgency,
    analyze_symptoms,
    combine_cfs,
    detect_red_flags,
)
pytestmark = pytest.mark.unit


# ═══════════════════════════════════════════════════════════════
# Certainty-factor combination
# ═══════════════════════════════════════════════════════════════
class TestCombineCFs:

    def test_two_positives(self):
        # 0.5 + 0.5*(1-0.5) = 0.75
        assert combine_cfs(0.5, 0.5) == pytest.approx(0.75)

    def test_two_negatives(self):
        # -0.5 + -0.5*(1 + -0.5) = -0.75
        assert combine_cfs(-0.5, -0.5) == pytest.approx(-0.75)

    def test_mixed_signs(self):
        # (0.5 + -0.3) / (1 - min(0.5, 0.3)) = 0.2 / 0.7 ≈ 0.2857
        assert combine_cfs(0.5, -0.3) == pytest.approx(0.2 / 0.7)

    def test_zero_neutral(self):
        assert combine_cfs(0.0, 0.5) == pytest.approx(0.5)
        assert combine_cfs(0.5, 0.0) == pytest.approx(0.5)


# ═══════════════════════════════════════════════════════════════
# Catalogue sanity
# ═══════════════════════════════════════════════════════════════
class TestCatalogue:

    def test_has_minimum_conditions(self):
        assert len(CONDITIONS) >= 20

    def test_unique_keys(self):
        keys = [c.key for c in CONDITIONS]
        assert len(keys) == len(set(keys))

    def test_every_condition_has_notes_and_recommendation(self):
        for c in CONDITIONS:
            assert c.notes_ar, f"{c.key} missing notes_ar"
            assert c.recommendation_ar, f"{c.key} missing recommendation_ar"

    def test_every_condition_has_positive_symptom(self):
        for c in CONDITIONS:
            assert any(w > 0 for w in c.symptoms.values()), \
                f"{c.key} has no positive symptoms"


# ═══════════════════════════════════════════════════════════════
# Golden-path diagnoses
# ═══════════════════════════════════════════════════════════════
class TestDiagnoses:

    def test_typical_caries(self):
        r = analyze_symptoms(
            ["ثقوب أو تجاويف ظاهرة",
             "حساسية للمشروبات الباردة أوالساخنة"],
            pain_severity=SEVERITY_MODERATE,
            age=30,
            location="الفك العلوي الأيسر",
        )
        assert r.primary.key == "dental_caries"
        assert r.primary.confidence >= 0.55
        assert r.urgency == Urgency.SOON

    def test_acute_pulpitis(self):
        r = analyze_symptoms(
            ["ألم نابض", "ألم يستمر بعد زوال المؤثر",
             "ألم يوقظ من النوم"],
            pain_severity=SEVERITY_SEVERE,
            age=28,
        )
        assert r.primary.key == "acute_pulpitis"
        # Escalated by severity on the URGENT tier — should be urgent.
        assert r.urgency == Urgency.URGENT

    def test_acute_apical_abscess_emergency(self):
        r = analyze_symptoms(
            ["ألم نابض", "تورم في الوجه أو اللثة",
             "حمى أو ارتفاع حرارة"],
            pain_severity=SEVERITY_SEVERE,
            swelling_severity=SEVERITY_SEVERE,
            age=35,
        )
        assert r.primary.key == "acute_apical_abscess"
        assert r.urgency == Urgency.EMERGENCY
        assert r.emergency_instructions

    def test_gingivitis(self):
        r = analyze_symptoms(
            ["نزيف لثوي عند التفريش", "احمرار وتورم اللثة"],
            age=25,
        )
        assert r.primary.key == "gingivitis"
        assert r.urgency == Urgency.ROUTINE

    def test_bruxism(self):
        r = analyze_symptoms(
            ["صرير الأسنان خلال النوم",
             "ألم في عضلات الفك عند الاستيقاظ",
             "صداع صباحي"],
            age=32,
        )
        assert r.primary.key == "bruxism"


# ═══════════════════════════════════════════════════════════════
# Contextual modulation
# ═══════════════════════════════════════════════════════════════
class TestContext:

    def test_age_gate_reduces_score(self):
        # pericoronitis has age 16–35; testing at age 50 should drop
        # its confidence significantly.
        young = analyze_symptoms(
            ["ألم في زاوية الفك الخلفية",
             "تورم اللثة حول السن الأخير",
             "صعوبة في فتح الفم"],
            age=22,
            location="الفك السفلي الأيسر",
        )
        old = analyze_symptoms(
            ["ألم في زاوية الفك الخلفية",
             "تورم اللثة حول السن الأخير",
             "صعوبة في فتح الفم"],
            age=50,
            location="الفك السفلي الأيسر",
        )
        # Find pericoronitis in both results
        def find(res, key):
            for m in res.all_matches:
                if m.key == key:
                    return m.confidence
            return 0.0

        assert find(young, "pericoronitis") > find(old, "pericoronitis")

    def test_location_boosts_preferred(self):
        right = analyze_symptoms(
            ["ألم في زاوية الفك الخلفية",
             "تورم اللثة حول السن الأخير"],
            age=22,
            location="الفك السفلي الأيسر",
        )
        wrong = analyze_symptoms(
            ["ألم في زاوية الفك الخلفية",
             "تورم اللثة حول السن الأخير"],
            age=22,
            location="الفك العلوي الأيمن",
        )

        def find(res, key):
            for m in res.all_matches:
                if m.key == key:
                    return m.confidence
            return 0.0

        assert find(right, "pericoronitis") > find(wrong, "pericoronitis")


# ═══════════════════════════════════════════════════════════════
# Pivotal symptom behaviour
# ═══════════════════════════════════════════════════════════════
class TestPivotal:

    def test_avulsion_with_pivotal_hits_floor(self):
        r = analyze_symptoms(
            ["انقلاع كامل للسن من مكانه",
             "إصابة أو كسر سن نتيجة رض"],
            age=20,
        )
        assert r.primary.key == "tooth_avulsion"
        assert r.primary.confidence >= 0.80   # pivotal floor
        assert r.urgency == Urgency.EMERGENCY

    def test_abscess_without_pivotal_capped(self):
        # Only pain — no swelling, no tenderness, no "tooth feels longer".
        r = analyze_symptoms(
            ["ألم نابض"],
            pain_severity=SEVERITY_MILD,
            age=30,
        )
        # Abscess must NOT appear as a top match, or if it does,
        # it must be capped at PIVOTAL_CAP.
        for m in r.all_matches:
            if m.key == "acute_apical_abscess":
                assert m.confidence <= PIVOTAL_CAP


# ═══════════════════════════════════════════════════════════════
# Contradicted-by (mutual exclusion)
# ═══════════════════════════════════════════════════════════════
class TestContradiction:

    def test_avulsion_excludes_fracture(self):
        r = analyze_symptoms(
            ["انقلاع كامل للسن من مكانه"],
            age=20,
        )
        keys = [m.key for m in r.all_matches]
        assert "tooth_fracture" not in keys

    def test_fracture_excludes_avulsion(self):
        r = analyze_symptoms(
            ["جزء من السن مفقود"],
            age=20,
        )
        keys = [m.key for m in r.all_matches]
        assert "tooth_avulsion" not in keys


# ═══════════════════════════════════════════════════════════════
# Red flags
# ═══════════════════════════════════════════════════════════════
class TestRedFlags:

    def test_detect_red_flags(self):
        flags = detect_red_flags([
            "حمى أو ارتفاع حرارة",
            "تورم ينتشر إلى العين أو الرقبة",
        ])
        assert len(flags) == 2

    def test_red_flag_forces_emergency(self):
        r = analyze_symptoms(
            ["حمى أو ارتفاع حرارة",
             "ثقوب أو تجاويف ظاهرة"],   # weak symptom set otherwise
            age=30,
        )
        assert r.urgency == Urgency.EMERGENCY
        assert r.emergency_instructions

    def test_red_flag_warning_added(self):
        r = analyze_symptoms(
            ["حمى أو ارتفاع حرارة", "ألم نابض"],
            pain_severity=SEVERITY_MODERATE,
            age=30,
        )
        assert any("طوارئ" in w for w in r.warnings)


# ═══════════════════════════════════════════════════════════════
# Result shape
# ═══════════════════════════════════════════════════════════════
class TestResultShape:

    def test_top_n_respected(self):
        r = analyze_symptoms(
            ["ألم نابض", "تورم في الوجه أو اللثة",
             "حمى أو ارتفاع حرارة", "ألم عند المضغ"],
            pain_severity=SEVERITY_SEVERE,
            swelling_severity=SEVERITY_SEVERE,
            top_n=2,
        )
        assert len(r.all_matches) <= 2

    def test_alternatives_are_sorted_desc(self):
        r = analyze_symptoms(
            ["نزيف لثوي", "احمرار وتورم اللثة",
             "رائحة كريهة للفم"],
            age=25,
        )
        confidences = [m.confidence for m in r.all_matches]
        assert confidences == sorted(confidences, reverse=True)


# ═══════════════════════════════════════════════════════════════
# Robustness
# ═══════════════════════════════════════════════════════════════
class TestRobustness:

    def test_empty_symptoms_raises(self):
        with pytest.raises(ValueError):
            analyze_symptoms([])

    def test_unknown_symptoms_raises(self):
        with pytest.raises(ValueError):
            analyze_symptoms(["سymptom لا وجود له"])

    def test_emergency_instructions_present_when_emergency(self):
        r = analyze_symptoms(
            ["حمى أو ارتفاع حرارة", "ألم نابض"],
            pain_severity=SEVERITY_SEVERE,
            age=30,
        )
        assert r.urgency == Urgency.EMERGENCY
        assert r.emergency_instructions == list(EMERGENCY_INSTRUCTIONS)