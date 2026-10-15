"""
External service mocks. Used via autouse fixtures in conftest.
"""
from typing import Any


class FakeCloudinaryResponse(dict):
    """Mimics Cloudinary's `upload` return shape."""
    pass


def fake_upload(*args: Any, **kwargs: Any) -> FakeCloudinaryResponse:
    public_id = kwargs.get("public_id") or "fake_public_id"
    folder = kwargs.get("folder", "test")
    return FakeCloudinaryResponse({
        "secure_url": (
            f"https://res.cloudinary.com/test/image/upload/v1/"
            f"{folder}/{public_id}.jpg"
        ),
        "public_id": f"{folder}/{public_id}",
    })


def fake_destroy(*args: Any, **kwargs: Any) -> dict:
    return {"result": "ok"}


def fake_upload_failure(*args: Any, **kwargs: Any) -> None:
    from cloudinary.exceptions import Error as CloudinaryError
    raise CloudinaryError("Simulated Cloudinary failure")


def fake_fcm_send(*args: Any, **kwargs: Any) -> str:
    """Simulated FCM success — returns a message id."""
    return "fake_fcm_message_id"