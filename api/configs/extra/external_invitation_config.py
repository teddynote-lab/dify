from pydantic import Field
from pydantic_settings import BaseSettings


class ExternalInvitationConfig(BaseSettings):
    """
    Configuration settings for external invitation API
    """

    EXTERNAL_INVITATION_ENABLED: bool = Field(
        description="Enable external invitation API endpoint for inviting editors via API key authentication",
        default=False,
    )

    EXTERNAL_INVITATION_API_KEY: str | None = Field(
        description="API key for authenticating external invitation requests. "
        "Must be set when EXTERNAL_INVITATION_ENABLED is True",
        default=None,
    )