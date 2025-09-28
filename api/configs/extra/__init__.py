from configs.extra.external_invitation_config import ExternalInvitationConfig
from configs.extra.notion_config import NotionConfig
from configs.extra.sentry_config import SentryConfig


class ExtraServiceConfig(
    # place the configs in alphabet order
    ExternalInvitationConfig,
    NotionConfig,
    SentryConfig,
):
    pass
