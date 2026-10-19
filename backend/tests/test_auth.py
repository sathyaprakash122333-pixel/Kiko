import os
import sys
import unittest
from pathlib import Path
from fastapi import HTTPException

backend_dir = str(Path(__file__).resolve().parent.parent)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from auth import verify_firebase_token, initialize_firebase_app


class AuthTestCase(unittest.TestCase):
    def test_invalid_token_rejected(self):
        # Without dev mode, invalid tokens must raise 401
        old_val = os.environ.get("KIKO_AUTH_DEV_MODE")
        os.environ["KIKO_AUTH_DEV_MODE"] = "false"
        try:
            with self.assertRaises(HTTPException) as cm:
                verify_firebase_token("invalid_garbage_token")
            self.assertEqual(cm.exception.status_code, 401)
        finally:
            if old_val is not None:
                os.environ["KIKO_AUTH_DEV_MODE"] = old_val
            else:
                os.environ.pop("KIKO_AUTH_DEV_MODE", None)

    def test_dev_mode_token_format(self):
        # When explicitly configured with KIKO_AUTH_DEV_MODE=true, dev:<uid> is parsed
        old_val = os.environ.get("KIKO_AUTH_DEV_MODE")
        os.environ["KIKO_AUTH_DEV_MODE"] = "true"
        try:
            data = verify_firebase_token("dev:student_abc")
            self.assertEqual(data["uid"], "student_abc")
            self.assertEqual(data["email"], "student_abc@kiko-dev.local")

            # Malformed dev token
            with self.assertRaises(HTTPException) as cm:
                verify_firebase_token("dev:")
            self.assertEqual(cm.exception.status_code, 401)
        finally:
            if old_val is not None:
                os.environ["KIKO_AUTH_DEV_MODE"] = old_val
            else:
                os.environ.pop("KIKO_AUTH_DEV_MODE", None)


if __name__ == "__main__":
    unittest.main()
