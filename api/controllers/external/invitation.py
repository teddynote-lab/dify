from flask import Blueprint, request
from flask_restx import Api, Resource, fields

from configs import dify_config
from controllers.external.wraps import external_api_key_required
from extensions.ext_database import db
from models.account import Account, Tenant, TenantAccountJoin, TenantAccountRole
from services.account_service import RegisterService
from services.errors.account import AccountAlreadyInTenantError


def register(external_api: Blueprint) -> Blueprint:
    """Register invitation endpoints to the external API blueprint"""
    api = Api(external_api)

    invitation_model = api.model(
        "InvitationRequest",
        {
            "emails": fields.List(fields.String, required=True, description="List of emails to invite"),
            "language": fields.String(required=False, default="en-US", description="Language for invitation email"),
        },
    )

    @api.route("/invite-editor")
    class InviteEditorApi(Resource):
        @external_api_key_required
        @api.doc(security={"apikey": []})
        @api.expect(invitation_model)
        def post(self):
            """
            Invite users as editors to the workspace

            This endpoint allows external services to invite users as editors
            to the workspace using API key authentication.
            """
            data = request.get_json()
            emails = data.get("emails", [])
            language = data.get("language", "en-US")

            if not emails:
                return {"success": False, "error": "No emails provided"}, 400

            # Get the first tenant (single tenant mode)
            tenant = db.session.query(Tenant).first()
            if not tenant:
                return {"success": False, "error": "No workspace found"}, 500

            # Get the first owner or admin to use as inviter
            inviter_query = (
                db.session.query(Account)
                .join(TenantAccountJoin, TenantAccountJoin.account_id == Account.id)
                .filter(
                    TenantAccountJoin.tenant_id == tenant.id,
                    TenantAccountJoin.role.in_([TenantAccountRole.OWNER, TenantAccountRole.ADMIN]),
                )
                .first()
            )

            if not inviter_query:
                return {"success": False, "error": "No admin account found"}, 500

            inviter = inviter_query
            invitation_results = []

            # Process each email
            for email in emails:
                try:
                    # Set inviter's current tenant for the invitation process
                    inviter.current_tenant = tenant

                    # Invite as editor
                    token = RegisterService.invite_new_member(
                        tenant=tenant,
                        email=email,
                        language=language,
                        role=TenantAccountRole.EDITOR,  # Fixed role as editor
                        inviter=inviter,
                    )

                    # Build activation URL
                    console_web_url = dify_config.CONSOLE_WEB_URL
                    activation_url = f"{console_web_url}/activate?email={email}&token={token}"

                    invitation_results.append(
                        {"email": email, "status": "success", "invitation_url": activation_url}
                    )
                except AccountAlreadyInTenantError:
                    # User is already in the workspace
                    invitation_results.append(
                        {"email": email, "status": "already_member", "message": "User is already a workspace member"}
                    )
                except Exception as e:
                    # Other errors
                    invitation_results.append({"email": email, "status": "failed", "message": str(e)})

            return {"success": True, "invitation_results": invitation_results}, 200

    return external_api