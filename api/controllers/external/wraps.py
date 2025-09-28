from collections.abc import Callable
from functools import wraps

from flask import request
from werkzeug.exceptions import Unauthorized

from configs import dify_config


def external_api_key_required(f: Callable) -> Callable:
    """
    Decorator to validate external API key authentication
    """

    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Check if external invitation API is enabled
        if not dify_config.EXTERNAL_INVITATION_ENABLED:
            raise Unauthorized("External invitation API is not enabled")

        # Get API key from configuration
        configured_api_key = dify_config.EXTERNAL_INVITATION_API_KEY
        if not configured_api_key:
            raise Unauthorized("External invitation API key is not configured")

        # Get API key from request header
        request_api_key = request.headers.get("X-API-Key")
        if not request_api_key:
            raise Unauthorized("API key is required in X-API-Key header")

        # Validate API key
        if request_api_key != configured_api_key:
            raise Unauthorized("Invalid API key")

        return f(*args, **kwargs)

    return decorated_function