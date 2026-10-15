"""
Domain-level exceptions & FastAPI exception handlers.

All errors follow a consistent JSON contract:
    { "detail": "...", "code": "ERROR_CODE" }
"""
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


# ═══════════════════════════════════════════════════════════════
# Base Exception
# ═══════════════════════════════════════════════════════════════
class AppException(Exception):
    """Base application exception."""

    status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR
    code: str = "INTERNAL_ERROR"
    message: str = "An unexpected error occurred."

    def __init__(self, message: str | None = None, code: str | None = None):
        self.message = message or self.message
        self.code = code or self.code
        super().__init__(self.message)


# ═══════════════════════════════════════════════════════════════
# Domain Exceptions
# ═══════════════════════════════════════════════════════════════
class ValidationException(AppException):
    status_code = status.HTTP_422_UNPROCESSABLE_ENTITY
    code = "VALIDATION_ERROR"
    message = "Invalid input data."


class UnauthorizedException(AppException):
    status_code = status.HTTP_401_UNAUTHORIZED
    code = "UNAUTHORIZED"
    message = "Authentication required."


class ForbiddenException(AppException):
    status_code = status.HTTP_403_FORBIDDEN
    code = "FORBIDDEN"
    message = "You don't have permission to perform this action."


class NotFoundException(AppException):
    status_code = status.HTTP_404_NOT_FOUND
    code = "NOT_FOUND"
    message = "Resource not found."


class ConflictException(AppException):
    status_code = status.HTTP_409_CONFLICT
    code = "CONFLICT"
    message = "Resource already exists."


class BadRequestException(AppException):
    status_code = status.HTTP_400_BAD_REQUEST
    code = "BAD_REQUEST"
    message = "Invalid request."


class TooManyRequestsException(AppException):
    status_code = status.HTTP_429_TOO_MANY_REQUESTS
    code = "TOO_MANY_REQUESTS"
    message = "Too many requests. Please slow down."


# ═══════════════════════════════════════════════════════════════
# Handlers
# ═══════════════════════════════════════════════════════════════
def register_exception_handlers(app: FastAPI) -> None:
    """Wire exception handlers into the FastAPI app."""

    @app.exception_handler(AppException)
    async def _app_exception_handler(_: Request, exc: AppException):
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.message, "code": exc.code},
        )

    @app.exception_handler(RequestValidationError)
    async def _validation_handler(_: Request, exc: RequestValidationError):
        # Pydantic v2 may include non-JSON-serialisable objects in `ctx`
        # (e.g. a raised ValueError). Stringify them defensively.
        safe_errors = []
        for err in exc.errors():
            clean = {k: v for k, v in err.items() if k != "ctx"}
            ctx = err.get("ctx")
            if ctx:
                clean["ctx"] = {k: str(v) for k, v in ctx.items()}
            safe_errors.append(clean)

        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "detail": "Invalid input data.",
                "code": "VALIDATION_ERROR",
                "errors": safe_errors,
            },
        )

    @app.exception_handler(Exception)
    async def _unhandled_handler(_: Request, exc: Exception):
        # Log full traceback in real code
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "detail": "Internal server error.",
                "code": "INTERNAL_ERROR",
            },
        )