"""End-to-end patient-case flow tests."""
import pytest

from app.domain.entities.patient_case import CaseStatus

from tests.helpers.factories import create_case

from tests.helpers.factories import create_user

pytestmark = pytest.mark.integration


# ═══════════════════════════════════════════════════════════════
# Preview
# ═══════════════════════════════════════════════════════════════
class TestPreview:

    async def test_preview_emergency(self, patient_client):
        resp = await patient_client.post("/api/v1/cases/preview", json={
            "symptoms": ["ألم نابض", "تورم في الوجه أو اللثة",
                         "حمى أو ارتفاع حرارة"],
            "location": "الفك العلوي الأيسر",
            "has_pain": True,
            "pain_severity": "شديد",
            "has_swelling": True,
            "swelling_severity": "شديد",
        })
        assert resp.status_code == 200, resp.text
        body = resp.json()
        assert body["primary"]["key"] == "acute_apical_abscess"
        assert body["urgency"] == "emergency"
        assert body["emergency_instructions"]

    async def test_preview_no_match_returns_400(self, patient_client):
        resp = await patient_client.post("/api/v1/cases/preview", json={
            "symptoms": ["عرض لا وجود له"],
            "location": "الفك العلوي الأيسر",
            "has_pain": False,
            "has_swelling": False,
        })
        assert resp.status_code == 400


# ═══════════════════════════════════════════════════════════════
# Create / List / Get / Update / Delete
# ═══════════════════════════════════════════════════════════════
class TestCRUD:

    async def test_create_case(self, patient_client):
        resp = await patient_client.post("/api/v1/cases", json={
            "symptoms": ["ثقوب أو تجاويف ظاهرة"],
            "location": "الفك العلوي الأيسر",
            "has_pain": True,
            "pain_severity": "متوسط",
            "has_swelling": False,
        })
        assert resp.status_code == 201, resp.text
        body = resp.json()
        assert body["status"] == "pending"
        assert body["diagnosis_confidence"] > 0.0

    async def test_list_mine(self, patient_client):
        for i in range(2):
            await patient_client.post("/api/v1/cases", json={
                "symptoms": ["ثقوب أو تجاويف ظاهرة"],
                "location": "الفك العلوي الأيسر",
                "has_pain": False,
                "has_swelling": False,
            })
        resp = await patient_client.get("/api/v1/cases?mine=true")
        assert resp.status_code == 200
        assert resp.json()["count"] == 2

    async def test_get_detail(self, patient_client):
        create = await patient_client.post("/api/v1/cases", json={
            "symptoms": ["ثقوب أو تجاويف ظاهرة"],
            "location": "الفك العلوي الأيسر",
            "has_pain": False,
            "has_swelling": False,
        })
        case_id = create.json()["id"]

        resp = await patient_client.get(f"/api/v1/cases/{case_id}")
        assert resp.status_code == 200
        assert resp.json()["id"] == case_id

    async def test_patch_pending(self, patient_client):
        create = await patient_client.post("/api/v1/cases", json={
            "symptoms": ["ثقوب أو تجاويف ظاهرة"],
            "location": "الفك العلوي الأيسر",
            "has_pain": False,
            "has_swelling": False,
        })
        case_id = create.json()["id"]

        resp = await patient_client.patch(f"/api/v1/cases/{case_id}", json={
            "location": "الفك السفلي الأيمن",
        })
        assert resp.status_code == 200
        assert resp.json()["location"] == "الفك السفلي الأيمن"

    async def test_delete_pending(self, patient_client):
        create = await patient_client.post("/api/v1/cases", json={
            "symptoms": ["ثقوب أو تجاويف ظاهرة"],
            "location": "الفك العلوي الأيسر",
            "has_pain": False,
            "has_swelling": False,
        })
        case_id = create.json()["id"]

        resp = await patient_client.delete(f"/api/v1/cases/{case_id}")
        assert resp.status_code == 204

        detail = await patient_client.get(f"/api/v1/cases/{case_id}")
        assert detail.status_code == 404


# ═══════════════════════════════════════════════════════════════
# Business rules
# ═══════════════════════════════════════════════════════════════
class TestBusinessRules:

    async def test_max_three_pending_cases(self, patient_client):
        # First three are accepted
        for i in range(3):
            resp = await patient_client.post("/api/v1/cases", json={
                "symptoms": ["ثقوب أو تجاويف ظاهرة"],
                "location": "الفك العلوي الأيسر",
                "has_pain": False,
                "has_swelling": False,
            })
            assert resp.status_code == 201

        # Fourth should fail
        resp = await patient_client.post("/api/v1/cases", json={
            "symptoms": ["ثقوب أو تجاويف ظاهرة"],
            "location": "الفك العلوي الأيسر",
            "has_pain": False,
            "has_swelling": False,
        })
        assert resp.status_code == 400

    async def test_doctor_cannot_create_case(self, doctor_client):
        resp = await doctor_client.post("/api/v1/cases", json={
            "symptoms": ["ثقوب أو تجاويف ظاهرة"],
            "location": "الفك العلوي الأيسر",
            "has_pain": False,
            "has_swelling": False,
        })
        assert resp.status_code == 403

    async def test_patient_cannot_see_others_case(
        self, patient_client, db_session, client,
    ):
        # Another patient

        from app.domain.entities.user import UserRole

        other = await create_user(
            db_session, role=UserRole.PATIENT,
            email="other@test.com", phone="0955555555",
        )
        case = await create_case(db_session, patient_id=other.id)

        resp = await patient_client.get(f"/api/v1/cases/{case.id}")
        assert resp.status_code == 403


# ═══════════════════════════════════════════════════════════════
# Doctor view: available cases
# ═══════════════════════════════════════════════════════════════
class TestDoctorView:

    async def test_doctor_sees_pending_cases(self, doctor_client, db_session, patient_user):
        await create_case(db_session, patient_id=patient_user.id)
        resp = await doctor_client.get("/api/v1/cases")
        assert resp.status_code == 200
        body = resp.json()
        assert body["count"] >= 1
        assert body["items"][0]["patient_name"] is not None

    async def test_doctor_sees_only_own_booked(self, doctor_client, db_session, patient_user):
        # Case booked by a *different* doctor
        from tests.helpers.factories import create_user
        from app.domain.entities.user import UserRole

        other_doc = await create_user(
            db_session, role=UserRole.DOCTOR,
            email="otherdoc@test.com", phone="0977777777",
            university_id="UNI-XYZ",
        )
        await create_case(
            db_session, patient_id=patient_user.id,
            status=CaseStatus.BOOKED, doctor_id=other_doc.id,
        )

        resp = await doctor_client.get("/api/v1/cases?status=booked")
        assert resp.status_code == 200
        assert resp.json()["count"] == 0