from flask import Blueprint


def get_external_api_blueprint() -> Blueprint:
    """Create and return the external API blueprint"""
    from controllers.external import invitation

    external_api = Blueprint("external_api", __name__, url_prefix="/api/v1/external")

    # Import resources after blueprint creation to avoid circular imports
    external_api = invitation.register(external_api)

    return external_api