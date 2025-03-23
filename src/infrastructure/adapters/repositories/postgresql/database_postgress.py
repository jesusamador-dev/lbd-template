from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.ext.declarative import declarative_base
import threading
import os


class DatabasePostgres:
    _instance: "DatabasePostgres" = None
    _lock: threading.Lock = threading.Lock()
    engine: "create_engine"
    SessionLocal: "sessionmaker"

    def __init__(self) -> None:
        """Constructor privado: Evita instanciación directa"""
        raise RuntimeError("Usa Database.get_instance() en lugar de instanciar directamente")

    @classmethod
    def get_instance(cls) -> "DatabasePostgres":
        """Método para obtener la única instancia de Database"""
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(DatabasePostgres, cls).__new__(cls)
                cls._instance._init_db()
        return cls._instance

    def _init_db(self) -> None:
        """Inicializa la conexión a la base de datos con variables de entorno"""
        db_user: str = os.getenv("DB_USER", "")
        db_password: str = os.getenv("DB_PASSWORD", "")
        db_host: str = os.getenv("DB_HOST", "")
        db_port: str = os.getenv("DB_PORT", "5432")
        db_name: str = os.getenv("DB_NAME", "")

        if not all([db_user, db_password, db_host, db_name]):
            raise ValueError("Faltan variables de entorno para la conexión a la base de datos")

        database_url: str = f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"

        self.engine = create_engine(database_url, pool_size=5, max_overflow=10, pool_pre_ping=True)
        self.SessionLocal = sessionmaker(bind=self.engine, autocommit=False, autoflush=False)

    def get_session(self) -> Session:
        """Crea una nueva sesión y la retorna"""
        return self.SessionLocal()

    def close(self) -> None:
        """Cierra la conexión"""
        self.engine.dispose()


# Declaración de la base para los modelos
Base = declarative_base()
