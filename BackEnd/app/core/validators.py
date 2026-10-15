"""
Reusable validators for Pydantic fields.

Password policy:
  • ≥ 12 characters
  • at least one letter
  • at least one digit
  • not in the common-password blacklist
  • not all the same character
"""
import re

# Minimal in-code blacklist — extend as needed.
# For production, replace with a loaded list (e.g. rockyou.txt top 100k).
COMMON_PASSWORDS: frozenset[str] = frozenset({
    "password", "password1", "password123", "123456789012",
    "qwertyuiop", "qwertyuiop12", "admin123456", "welcome12345",
    "iloveyou123", "monkey123456", "dragon123456", "letmein12345",
    "abcd12345678", "012345678901", "aaaaaaaaaaaa", "111111111111",
    "passwordpassword", "administrator", "welcomewelcome",
})

_MIN_LEN = 12
_MAX_LEN = 128
_has_letter = re.compile(r"[A-Za-z\u0600-\u06FF]")   # Latin or Arabic
_has_digit = re.compile(r"\d")


def validate_password_strength(value: str) -> str:
    """Raise ValueError with a clear message if the password is weak."""
    if not isinstance(value, str):
        raise ValueError("Password must be a string.")

    # Length checks first
    if len(value) < _MIN_LEN:
        raise ValueError(f"Password must be at least {_MIN_LEN} characters.")
    if len(value) > _MAX_LEN:
        raise ValueError(f"Password must be at most {_MAX_LEN} characters.")

    # ★ Single-character check BEFORE letter/digit — it is the more
    #   specific failure and gives a clearer message.
    if len(set(value)) == 1:
        raise ValueError("Password cannot consist of a single repeated character.")

    # Content checks
    if not _has_letter.search(value):
        raise ValueError("Password must contain at least one letter.")
    if not _has_digit.search(value):
        raise ValueError("Password must contain at least one digit.")

    # Blacklist
    if value.lower() in COMMON_PASSWORDS:
        raise ValueError("This password is too common. Choose a stronger one.")

    return value