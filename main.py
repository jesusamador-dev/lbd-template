from mangum import Mangum
from fastapi import FastAPI
from src.presentation.middlewares.setup_exception_handlers import setup_exception_handlers
from src.presentation.middlewares.standardize_response_middleware import standardize_response

app = FastAPI()
setup_exception_handlers(app)
app.middleware("http")(standardize_response)

handler = Mangum(app)
