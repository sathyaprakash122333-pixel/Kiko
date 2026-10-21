import logging
import os
from pathlib import Path
import re
import sqlite3
from sqlalchemy import create_engine, event
from sqlalchemy.engine import Engine
from sqlalchemy.engine.url import make_url
from sqlalchemy.orm import DeclarativeBase, sessionmaker

logger = logging.getLogger("kiko.database")

DEFAULT_DB_PATH = Path(__file__).resolve().parent / "kiko.db"


def mask_db_url(url: str) -> str:
    """Masks database password and sensitive tokens for safe logging and error reporting."""
    try:
        parsed = make_url(url)
        return parsed.render_as_string(hide_password=True)
    except Exception:
        return re.sub(r":([^@/]+)@", ":******@", str(url))


def normalize_database_url(raw_url: str | None) -> str:
    """
    Safely sanitizes, unquotes, and normalizes DATABASE_URL from environment variables.
    Handles:
    - Trailing/leading whitespace and newlines
    - Single and double quotes often added in cloud dashboards ('...' or "...")
    - Multiline blocks (e.g. copying URI and parameters block from Supabase dashboard)
    - DATABASE_URL= prefix if copied from a .env file
    - postgres:// and postgresql:// conversion to postgresql+psycopg2://
    """
    if not raw_url or not str(raw_url).strip():
        return f"sqlite:///{DEFAULT_DB_PATH}"

    val = str(raw_url).strip()

    # 1. Strip 'DATABASE_URL=' prefix if copied from .env file
    if val.upper().startswith("DATABASE_URL="):
        val = val[len("DATABASE_URL="):].strip()

    # 2. Strip surrounding quotes repeatedly (e.g. "'url'" or '"url"')
    while (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
        val = val[1:-1].strip()

    # 3. Handle multiline inputs (e.g. copying URI + parameters block from Supabase)
    lines = [line.strip().strip('"').strip("'") for line in val.splitlines() if line.strip()]
    url_line = None
    for line in lines:
        if line.startswith(("postgres://", "postgresql://", "sqlite://")):
            url_line = line
            break

    if url_line:
        val = url_line
    elif len(lines) > 1 and any("=" in l for l in lines):
        # Fallback: parse key-value parameters host=... port=... user=...
        params = {}
        for line in lines:
            if "=" in line:
                k, v = line.split("=", 1)
                params[k.strip().lower()] = v.strip().strip('"').strip("'")
        if "host" in params:
            user = params.get("user", "postgres")
            password = params.get("password", "")
            host = params.get("host")
            port = params.get("port", "5432")
            database = params.get("database", params.get("dbname", "postgres"))
            auth = f"{user}:{password}@" if password else f"{user}@"
            val = f"postgresql://{auth}{host}:{port}/{database}"

    # 4. Strip quotes once more in case url_line was quoted
    while (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
        val = val[1:-1].strip()

    # 5. Normalize dialect/driver prefix to postgresql+psycopg2
    if val.startswith("postgres://"):
        val = val.replace("postgres://", "postgresql+psycopg2://", 1)
    elif val.startswith("postgresql://") and not val.startswith("postgresql+"):
        val = val.replace("postgresql://", "postgresql+psycopg2://", 1)

    # 6. Validate via SQLAlchemy make_url
    try:
        parsed = make_url(val)
        if not parsed.drivername:
            raise ValueError("Missing database scheme in connection string")
    except Exception:
        masked = mask_db_url(val)
        logger.error("Failed to parse database URL: %s", masked)
        raise ValueError(
            f"Invalid DATABASE_URL format (sanitized: {masked}). "
            "Please ensure DATABASE_URL is a valid URI starting with postgresql:// or sqlite:///"
        ) from None

    return val


DATABASE_URL = normalize_database_url(os.getenv("DATABASE_URL"))
is_sqlite = DATABASE_URL.startswith("sqlite")

engine_kwargs = {}
if is_sqlite:
    engine_kwargs["connect_args"] = {"check_same_thread": False}
else:
    # PostgreSQL connection pooling optimizations for Render and Supabase
    engine_kwargs.update({
        "pool_pre_ping": True,
        "pool_recycle": 300,
        "pool_size": 10,
        "max_overflow": 20,
    })

try:
    engine = create_engine(DATABASE_URL, **engine_kwargs)
except Exception as exc:
    masked_url = mask_db_url(DATABASE_URL)
    logger.critical("Failed to create SQLAlchemy engine with URL: %s (%s)", masked_url, exc)
    raise ValueError(f"Could not initialize database engine with provided DATABASE_URL ({masked_url})") from exc


@event.listens_for(Engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    """Enforces SQLite foreign key constraints and cascading deletes."""
    if isinstance(dbapi_connection, sqlite3.Connection):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()


SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
)


class Base(DeclarativeBase):
    pass


def get_db():
    """Canonical database session generator for FastAPI dependencies."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
