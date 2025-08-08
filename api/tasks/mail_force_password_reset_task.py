import logging
import time

import click
from celery import shared_task  # type: ignore

from configs import dify_config
from extensions.ext_mail import mail
from libs.email_i18n import EmailType, get_email_i18n_service


@shared_task(queue="mail")
def send_force_password_reset_mail_task(language: str, to: str, new_password: str) -> None:
    """
    Send force password reset email with new password.

    Args:
        language: Language code for email localization
        to: Recipient email address
        new_password: The new password that was set
    """
    if not mail.is_inited():
        return

    logging.info(click.style(f"Start force password reset mail to {to}", fg="green"))
    start_at = time.perf_counter()

    try:
        # Get console web URL from config
        console_web_url = dify_config.CONSOLE_WEB_URL or "https://dify.ai"
        
        email_service = get_email_i18n_service()
        email_service.send_email(
            email_type=EmailType.FORCE_PASSWORD_RESET,
            language_code=language,
            to=to,
            template_context={
                "email": to,
                "password": new_password,
                "url": console_web_url,
            },
        )

        end_at = time.perf_counter()
        logging.info(
            click.style(f"Send force password reset mail to {to} succeeded: latency: {end_at - start_at}", fg="green")
        )
    except Exception:
        logging.exception("Send force password reset mail to %s failed", to)