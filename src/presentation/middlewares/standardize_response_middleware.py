from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import json
from src.presentation.dtos.response_dto import SuccessResponse, ErrorResponse

app = FastAPI()


@app.middleware("http")
async def standardize_response(request: Request, call_next):
    response = await call_next(request)
    body_parts = []
    async for chunk in response.body_iterator:
        body_parts.append(chunk)
    body = b''.join(body_parts)
    if 'content-length' in response.headers:
        del response.headers['content-length']
    if 200 <= response.status_code < 300:
        data = json.loads(body.decode())
        standardized_response = SuccessResponse(data=data)
        return JSONResponse(
            content=standardized_response.dict(),
            status_code=response.status_code,
            headers=response.headers)
    else:

        error_data = json.loads(body.decode())

        error_response = ErrorResponse(
            error="An error occurred",
            data=error_data,
        )
        return JSONResponse(
            content=error_response.dict(),
            status_code=response.status_code,
            headers=response.headers)

