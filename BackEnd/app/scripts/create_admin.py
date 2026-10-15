"""
CLI script to bootstrap the first admin account.

Usage (from project root, with virtualenv activated):
    python -m app.scripts.create_admin

Design notes:
- This is a DELIVERY MECHANISM, exactly like an HTTP router.
  It orchestrates calls to the service layer — it contains NO business logic.
- Never expose admin-creation through the HTTP API.
- Password input is hidden (getpass).
- Reads env config from .env like the rest of the app.
"""
import asyncio
import getpass
import sys

from pydantic import ValidationError

from app.application.dtos.auth_dto import CreateAdminRequest
from app.application.services.auth_service import AuthService
from app.core.exceptions import ConflictException
from app.infrastructure.database.session import AsyncSessionLocal


# ═══════════════════════════════════════════════════════════════
# Input
# ═══════════════════════════════════════════════════════════════
def _prompt_admin_data() -> CreateAdminRequest:
    """Interactively collect admin data with validation."""
    print("=" * 60)
    print("  DentSpace — Bootstrap First Admin Account")
    print("=" * 60)

    full_name = input("Full name           : ").strip()
    email     = input("Email               : ").strip()
    phone     = input("Phone (09xx / +9639): ").strip()
    password  = getpass.getpass("Password (min 12)   : ")
    confirm   = getpass.getpass("Confirm password    : ")

    try:
        return CreateAdminRequest(
            full_name=full_name,
            email=email,
            phone=phone,
            password=password,
            confirm_password=confirm,
        )
    except ValidationError as e:
        print("\n❌ Invalid input:")
        for err in e.errors():
            loc = ".".join(str(p) for p in err["loc"])
            print(f"   - {loc}: {err['msg']}")
        sys.exit(1)


# ═══════════════════════════════════════════════════════════════
# Execution
# ═══════════════════════════════════════════════════════════════
async def _run() -> None:
    """Collect input, call the service, print the result."""
    data = _prompt_admin_data()

    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        try:
            admin = await service.create_admin(data)
            await session.commit()
        except ConflictException as e:
            await session.rollback()
            print(f"\n⚠️  {e}")
            sys.exit(2)
        except Exception as e:
            await session.rollback()
            print(f"\n❌ Unexpected error: {e}")
            raise

        print("\n✅ Admin created successfully!")
        print(f"   ID    : {admin.id}")
        print(f"   Email : {admin.email}")
        print(f"   Role  : {admin.role.value}")


def main() -> None:
    """Entry point — handles Ctrl+C gracefully."""
    try:
        asyncio.run(_run())
    except KeyboardInterrupt:
        print("\n\nCancelled by user.")
        sys.exit(130)


if __name__ == "__main__":
    main()