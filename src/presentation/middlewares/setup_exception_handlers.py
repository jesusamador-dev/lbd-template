from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError


def setup_exception_handlers(app):
    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        errors = exc.errors()
        simplified_errors: list = []

        for error in errors:
            error_simplified = {"detail": error['msg'], "ctx": error['ctx'], "key": error['loc'][-1]}
            simplified_errors.append(error_simplified)

        return JSONResponse(
            status_code=422,
            content=simplified_errors
        )
