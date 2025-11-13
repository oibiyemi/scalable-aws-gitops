from pydantic_settings import BaseSettings, SettingsConfigDict

class AppSettings(BaseSettings):
    """
    Loads configuration from environment variables.
    Pydantic handles validation and type casting.
    """
    # model_config = SettingsConfigDict(env_file='.env', env_file_encoding='utf-8')

    APP_NAME: str = "Scalable FastAPI Service"
    LOG_LEVEL: str = "INFO"
    
    # These would be used if we were connecting to our services
    # We define defaults so the app can run, but in prod,
    # these would be set by our environment.
    POSTGRES_USER: str = "default_user"
    POSTGRES_PASSWORD: str = "default_pass"
    POSTGRES_DB: str = "default_db"
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432

    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379

    @property
    def database_url(self) -> str:
        """Constructs the database URL from parts."""
        return f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"

# Create a single, importable instance of the settings
settings = AppSettings()
