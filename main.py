from typing import Dict

from fastapi import FastAPI
from src.infrastructure.repositories.postgresql.database_postgress import DatabasePostgres

app = FastAPI()


@app.get("/")
async def root() -> Dict[str, str]:  # Agregamos el tipo de retorno
    return {"message": "Hello World"}


@app.get("/hello/{name}")
async def say_hello(name: str) -> Dict[str, str]:  # Agregamos el tipo de retorno
    return {"message": f"Hello {name}"}


@app.on_event("shutdown")
def shutdown():
    DatabasePostgres.get_instance().close()
