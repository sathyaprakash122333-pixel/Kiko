import logging
import os
from datetime import datetime, timezone
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import firebase_admin
from firebase_admin import auth as firebase_auth, credentials
from sqlalchemy.orm import Session

from database import SessionLocal
from models import User

logger = logging.getLogger("kiko.auth")

# HTTP Bearer scheme
bearer_scheme = HTTPBearer(auto_error=False)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def initialize_firebase_app():
    """Initializes the Firebase Admin SDK once if not already initialized."""
    if firebase_admin._apps:
        return

    service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_KEY")
    project_id = os.getenv("FIREBASE_PROJECT_ID", "kiko-894c7")

    try:
        if service_account_path and os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred, {"projectId": project_id})
            logger.info("Firebase Admin initialized with service account key: %s", service_account_path)
        else:
            firebase_admin.initialize_app(options={"projectId": project_id})
            logger.info("Firebase Admin initialized with project ID: %s", project_id)
    except Exception as exc:
        logger.warning("Firebase Admin initialization note: %s", exc)


def verify_firebase_token(token: str) -> dict:
    """
    Verifies a Firebase ID token.
    If KIKO_AUTH_DEV_MODE is explicitly set to 'true', allows 'dev:<uid>' tokens for local offline testing.
    """
    initialize_firebase_app()

    dev_mode = os.getenv("KIKO_AUTH_DEV_MODE", "false").lower() in ("true", "1", "yes")
    if dev_mode and token.startswith("dev:"):
        dev_uid = token.split("dev:", 1)[1].strip()
        if not dev_uid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid dev token format. Expected dev:<firebase_uid>",
            )
        return {
            "uid": dev_uid,
            "email": f"{dev_uid}@kiko-dev.local",
            "name": f"Dev User ({dev_uid})",
        }

    try:
        decoded_token = firebase_auth.verify_id_token(token)
        return decoded_token
    except firebase_auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase ID token has expired",
        )
    except firebase_auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Firebase ID token",
        )
    except Exception as exc:
        logger.error("Firebase token verification failure: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed: unable to verify Firebase ID token",
        )


def get_current_user(
    auth_header: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    """
    Dependency that enforces authentication for protected endpoints.
    Extracts Bearer token, verifies via Firebase, and returns or syncs the User model.
    """
    if not auth_header or not auth_header.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Bearer authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = auth_header.credentials
    token_data = verify_firebase_token(token)
    uid = token_data.get("uid")

    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token does not contain a valid user identity (UID)",
        )

    now = datetime.now(timezone.utc)

    # Sync user in local database
    user = db.query(User).filter(User.firebase_uid == uid).first()
    if not user:
        user = User(
            firebase_uid=uid,
            email=token_data.get("email"),
            display_name=token_data.get("name"),
            created_at=now,
            last_login_at=now,
        )
        db.add(user)
        try:
            db.commit()
            db.refresh(user)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to register user in database",
            )
    else:
        # Update email/name if changed and refresh last_login_at
        user.last_login_at = now
        new_email = token_data.get("email")
        new_name = token_data.get("name")
        if new_email and user.email != new_email:
            user.email = new_email
        if new_name and not user.display_name:
            user.display_name = new_name
        try:
            db.commit()
            db.refresh(user)
        except Exception:
            db.rollback()

    return user
