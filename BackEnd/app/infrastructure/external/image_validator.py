"""
Magic-byte validation for uploaded images.

Never trust the client-provided Content-Type. Inspect the first bytes
of the file instead. Accepts: JPEG, PNG, WEBP.

Raises `BadRequestException` on failure so it integrates seamlessly
with the service layer.
"""
from app.core.exceptions import BadRequestException


# ─── Signatures ────────────────────────────────────────────────
_JPEG = (b"\xff\xd8\xff",)
_PNG  = (b"\x89PNG\r\n\x1a\n",)
_WEBP = None  # handled specially (RIFF...WEBP at offset 8)


def _sniff(buf: bytes) -> str | None:
    if any(buf.startswith(sig) for sig in _JPEG):
        return "image/jpeg"
    if buf.startswith(_PNG):
        return "image/png"
    if len(buf) >= 12 and buf[:4] == b"RIFF" and buf[8:12] == b"WEBP":
        return "image/webp"
    return None


def validate_image_bytes(data: bytes, *, declared_type: str | None) -> str:
    """
    Return a canonical MIME type if the file is a valid image.

    Parameters
    ----------
    data           : the first N bytes of the file (≥ 16 recommended).
    declared_type  : what the client claimed (informational; ignored for trust).

    Raises
    ------
    BadRequestException
        If the file does not match any supported format, or if the
        declared type contradicts the sniffed type.
    """
    if not data or len(data) < 12:
        raise BadRequestException("File is too small to be a valid image.")

    sniffed = _sniff(data)
    if sniffed is None:
        raise BadRequestException(
            "Unsupported file format. Only JPEG, PNG, and WEBP are allowed."
        )

    # If the client sent a Content-Type, it must match the sniffed type.
    # (Some browsers send image/jpg — accept it as JPEG.)
    if declared_type:
        declared = declared_type.lower()
        if declared == "image/jpg":
            declared = "image/jpeg"
        if declared.startswith("image/") and declared != sniffed:
            raise BadRequestException(
                f"Content-Type mismatch: declared '{declared_type}' "
                f"but file is '{sniffed}'."
            )

    return sniffed