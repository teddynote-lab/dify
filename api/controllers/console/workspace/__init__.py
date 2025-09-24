from collections.abc import Callable
from functools import wraps
from typing import ParamSpec, TypeVar

from flask_login import current_user
from sqlalchemy.orm import Session

from extensions.ext_database import db
from models.account import TenantPluginPermission

P = ParamSpec("P")
R = TypeVar("R")


def plugin_permission_required(
    install_required: bool = False,
    debug_required: bool = False,
):
    def interceptor(view: Callable[P, R]):
        @wraps(view)
        def decorated(*args: P.args, **kwargs: P.kwargs):
            user = current_user
            tenant_id = user.current_tenant_id

            with Session(db.engine) as session:
                permission = (
                    session.query(TenantPluginPermission)
                    .where(
                        TenantPluginPermission.tenant_id == tenant_id,
                    )
                    .first()
                )

                if not permission:
                    # no permission set, default to admin/owner only
                    if install_required or debug_required:
                        if not user.is_admin_or_owner:
                            # Return empty success response instead of raising Forbidden
                            return {"success": True}
                    return view(*args, **kwargs)

                if install_required:
                    if permission.install_permission == TenantPluginPermission.InstallPermission.NOBODY:
                        # Return empty success response instead of raising Forbidden
                        return {"success": True}
                    if permission.install_permission == TenantPluginPermission.InstallPermission.ADMINS:
                        if not user.is_admin_or_owner:
                            # Return empty success response instead of raising Forbidden
                            return {"success": True}
                    if permission.install_permission == TenantPluginPermission.InstallPermission.EVERYONE:
                        pass

                if debug_required:
                    if permission.debug_permission == TenantPluginPermission.DebugPermission.NOBODY:
                        # Return empty success response instead of raising Forbidden
                        return {"success": True}
                    if permission.debug_permission == TenantPluginPermission.DebugPermission.ADMINS:
                        if not user.is_admin_or_owner:
                            # Return empty success response instead of raising Forbidden
                            return {"success": True}
                    if permission.debug_permission == TenantPluginPermission.DebugPermission.EVERYONE:
                        pass

            return view(*args, **kwargs)

        return decorated

    return interceptor
