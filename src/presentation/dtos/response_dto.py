from typing import Union, List, Dict, Any

from pydantic import BaseModel, Field
from uuid import uuid4


class SuccessResponse(BaseModel):
    responseId: str = Field(default_factory=lambda: str(uuid4()), description="Unique ID for the response.")
    success: bool = Field(default=True, description="Indicates if the operation was successful.")
    data: dict = Field(default={}, description="Data payload of the response.")


class ErrorResponse(BaseModel):
    responseId: str = Field(default_factory=lambda: str(uuid4()), description="Unique ID for the response.")
    success: bool = Field(default=False, description="Indicates if the operation was unsuccessful.")
    error: str = Field(description="Error message describing the issue.")
    data:  Union[str, List[Any], Dict[str, Any]] = Field(default={}, description="Additional details about the error if available.")
