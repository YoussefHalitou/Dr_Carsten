from functools import lru_cache
from typing import List

from pydantic import AnyHttpUrl, BaseSettings, Field, HttpUrl, validator


class Settings(BaseSettings):
    environment: str = Field(default="development", env="ENVIRONMENT")
    debug: bool = Field(default=False, env="DEBUG")
    openai_api_key: str = Field(..., env="OPENAI_API_KEY")
    database_url: str = Field(..., env="DATABASE_URL")
    port: int = Field(default=8000, env="PORT")
    cors_origins: str = Field(default="http://localhost:3000", env="CORS_ORIGINS")
    api_key: str = Field(..., env="API_KEY")
    enforce_https: bool = Field(default=True, env="ENFORCE_HTTPS")
    sqlalchemy_echo: bool = Field(default=False, env="SQLALCHEMY_ECHO")

    @validator("cors_origins")
    def split_origins(cls, value: str) -> List[str]:
        return [origin.strip() for origin in value.split(",") if origin.strip()]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()

