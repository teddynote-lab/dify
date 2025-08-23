from dify_app import DifyApp


def init_app(app: DifyApp):
    from events import event_handlers  # noqa: F401

    # Import all task modules to register them with Celery
    from tasks import (  # noqa: F401
        delete_account_task,
        mail_account_deletion_task,
        mail_change_mail_task,
        mail_email_code_login,
        mail_force_password_reset_task,
        mail_inner_task,
        mail_invite_member_task,
        mail_owner_transfer_task,
        mail_reset_password_task,
    )
