from typing import Dict

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
async def root() -> Dict[str, str]:  # Agregamos el tipo de retorno
    return {"message": "Hello World"}


@app.get("/hello/{name}")
async def say_hello(name: str) -> Dict[str, str]:  # Agregamos el tipo de retorno
    return {"message": f"Hello {name}"}
