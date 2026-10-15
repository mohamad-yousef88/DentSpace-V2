"""
Push notification delivery via Firebase Cloud Messaging.

Contract:
- `send_to_token()` NEVER raises. Returns True/False.
- Returns False with `reason='unregistered'` when the token is dead —
  the caller is expected to clear it from the user record.

Android presentation
--------------------
The mobile app declares:
  • channel       = `dentspace_channel`
  • icon          = `ic_notification`        (medical bag, white-only)
  • accent colour = `@color/notification_accent`
      → resolved locally from values/colors.xml (light) and
        values-night/colors.xml (dark)

We must mirror the channel id and the icon here. We deliberately do
NOT send `color` — otherwise Android would ignore the local resource
and the accent could not adapt to light/dark mode.
"""
import logging
from dataclasses import dataclass

from firebase_admin import messaging

from app.infrastructure.external.firebase_admin import is_enabled

logger = logging.getLogger(__name__)

# ═══════════════════════════════════════════════════════════════
# Android presentation constants — must match the Flutter app.
# ═══════════════════════════════════════════════════════════════
ANDROID_CHANNEL_ID = "dentspace_channel"
ANDROID_ICON = "ic_notification"


@dataclass(frozen=True)
class PushResult:
    success: bool
    reason: str = ""  # 'unregistered' | 'internal' | 'disabled' | 'no_token'


class PushService:

    def send_to_token(
        self,
        token: str | None,
        *,
        title: str,
        body: str | None = None,
        data: dict | None = None,
    ) -> PushResult:
        if not token:
            return PushResult(False, "no_token")
        if not is_enabled():
            return PushResult(False, "disabled")

        try:
            message = messaging.Message(
                token=token,
                notification=messaging.Notification(
                    title=title,
                    body=body or "",
                ),
                data={k: str(v) for k, v in (data or {}).items()},
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        channel_id=ANDROID_CHANNEL_ID,
                        sound="default",
                        icon=ANDROID_ICON,
                        # `color` intentionally omitted — resolved locally
                        # via @color/notification_accent so it adapts to
                        # light/dark mode.
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(sound="default", badge=1),
                    ),
                ),
            )
            messaging.send(message)
            return PushResult(True)

        except messaging.UnregisteredError:
            logger.info("FCM token unregistered — should be cleared.")
            return PushResult(False, "unregistered")

        except messaging.SenderIdMismatchError:
            logger.warning(
                "FCM sender-id mismatch — token belongs to another project."
            )
            return PushResult(False, "unregistered")

        except Exception as exc:
            logger.error("FCM send failed: %s", exc)
            return PushResult(False, "internal")


push_service = PushService()