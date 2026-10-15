"""Unit tests for app.core.validators.validate_password_strength."""
import pytest

from app.core.validators import (
    COMMON_PASSWORDS,
    validate_password_strength,
)

pytestmark = pytest.mark.unit


# ═══════════════════════════════════════════════════════════════
# Happy path
# ═══════════════════════════════════════════════════════════════
@pytest.mark.parametrize("password", [
    "MyStrongPass123!",
    "abcd1234efgh",           # exactly 12, letters + digits
    "SecurePass2025",
    "Test12345678",
    "Aa1!Aa1!Aa1!",
])
def test_valid_passwords_pass(password: str):
    assert validate_password_strength(password) == password


# ═══════════════════════════════════════════════════════════════
# Rejections
# ═══════════════════════════════════════════════════════════════
def test_too_short():
    with pytest.raises(ValueError, match="at least 12"):
        validate_password_strength("Short1")


def test_no_letter():
    with pytest.raises(ValueError, match="at least one letter"):
        validate_password_strength("123456789012")


def test_no_digit():
    with pytest.raises(ValueError, match="at least one digit"):
        validate_password_strength("OnlyLettersHere")


def test_single_repeated_character():
    with pytest.raises(ValueError, match="single repeated character"):
        validate_password_strength("aaaaaaaaaaaa")


def test_common_password_rejected():
    # All members of the blacklist must be rejected (some may fail
    # earlier checks, so we only check that *some* error is raised).
    for pw in COMMON_PASSWORDS:
        with pytest.raises(ValueError):
            validate_password_strength(pw)


def test_too_long():
    with pytest.raises(ValueError, match="at most 128"):
        validate_password_strength("Aa1" * 100)


def test_non_string():
    with pytest.raises(ValueError):
        validate_password_strength(12345)  # type: ignore[arg-type]


# ═══════════════════════════════════════════════════════════════
# Arabic letters accepted
# ═══════════════════════════════════════════════════════════════
def test_arabic_letters_accepted():
    assert validate_password_strength("كلمةمرور1234") == "كلمةمرور1234"