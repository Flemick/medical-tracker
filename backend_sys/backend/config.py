import os
from dotenv import load_dotenv

# Load .env with override so fresh values always win over stale env
load_dotenv(override=True)

class _ConfigMeta(type):
    @property
    def SUPABASE_URL(cls):
        v = os.environ.get('SUPABASE_URL', '')
        return v.strip().strip("'\"") if v else ''

    @property
    def SUPABASE_KEY(cls):
        v = os.environ.get('SUPABASE_KEY', '')
        return v.strip().strip("'\"") if v else ''

    @property
    def SUPABASE_SERVICE_KEY(cls):
        v = os.environ.get('SUPABASE_SERVICE_KEY', '')
        return v.strip().strip("'\"") if v else ''


class Config(metaclass=_ConfigMeta):
    @staticmethod
    def _get(key, default=None):
        """Always read from live os.environ (supports reload)."""
        return os.environ.get(key, default)

    @staticmethod
    def validate():
        load_dotenv(override=True)
        url = os.environ.get('SUPABASE_URL')
        key = os.environ.get('SUPABASE_KEY')
        svc = os.environ.get('SUPABASE_SERVICE_KEY')
        if not url or not key:
            raise ValueError(
                "Missing SUPABASE_URL or SUPABASE_KEY in environment variables. "
                "Make sure you have a .env file in the project root."
            )
        if not svc:
            import warnings
            warnings.warn(
                "SUPABASE_SERVICE_KEY is not set. Write operations will be blocked by RLS.",
                stacklevel=2
            )
