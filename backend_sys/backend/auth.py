import os
import sys
from functools import wraps
from flask import request, jsonify, g

# Ensure local directory is in Python path for all environments & IDE language servers
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

try:
    from supabase_client import get_db_client, get_admin_client  # type: ignore
except ImportError:
    from backend.supabase_client import get_db_client, get_admin_client  # type: ignore


def get_auth_token():
    """Extract Bearer token from Authorization header."""
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    return auth_header.split(" ")[1]


def get_user_from_token(token):
    """Retrieve user and profile directly from Supabase Auth token."""
    supabase = get_db_client()   # anon client for auth.get_user
    db = get_admin_client()       # admin client for profiles table (bypasses RLS)
    try:
        user_res = supabase.auth.get_user(token)
        if not user_res or not user_res.user:
            return None, None
        
        user_id = user_res.user.id
        profile_res = db.table('profiles').select('*').eq('id', user_id).execute()
        profile = profile_res.data[0] if profile_res.data else None
        
        return user_res.user, profile
    except Exception as e:
        print(f"Auth verification error: {e}")
        return None, None


def require_auth(allowed_roles=None):
    """
    Decorator to protect Flask routes.
    :param allowed_roles: List of allowed user roles e.g. ['ADMIN', 'NURSE']
    """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            token = get_auth_token()
            if not token:
                return jsonify({
                    "error": "Unauthorized",
                    "message": "Missing or invalid Authorization header."
                }), 401
            
            user, profile = get_user_from_token(token)
            if not user or not profile:
                return jsonify({
                    "error": "Unauthorized",
                    "message": "Invalid session token or profile not found."
                }), 401

            if not profile.get('is_active', True):
                return jsonify({
                    "error": "Forbidden",
                    "message": "Your account has been disabled."
                }), 403

            if allowed_roles and profile.get('role') not in allowed_roles:
                return jsonify({
                    "error": "Forbidden",
                    "message": f"Access denied. Requires one of roles: {allowed_roles}"
                }), 403

            setattr(request, 'current_user', user)
            setattr(request, 'current_profile', profile)
            g.current_user = user
            g.current_profile = profile
            return f(*args, **kwargs)
        return decorated_function
    return decorator
