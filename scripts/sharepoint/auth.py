# auth.py
# Handles environment loading and MSAL token acquisition.

import os
from typing import Tuple, Optional, Dict, Any
import requests
from msal import PublicClientApplication


def load_environment() -> Tuple[str, str]:
    """
    Loads environment variables from .env and *guarantees* valid strings.

    Returns:
        (tenant_id, client_id)

    Raises:
        RuntimeError if required environment variables are missing.
    """
    tenant = os.getenv("PNP_TENANT_ID")
    client = os.getenv("PNP_CLIENT_ID")

    if not tenant or not client:
        raise RuntimeError(
            "Missing required environment variables: "
            "PNP_TENANT_ID or PNP_CLIENT_ID in .env"
        )

    return tenant, client


def acquire_token(tenant: str, client: str) -> Dict[str, Any]:
    """
    Interactive browser auth for SharePoint delegated permissions.
    """
    authority = f"https://login.microsoftonline.com/{tenant}"
    scopes = ["https://evboise.sharepoint.com/.default"]

    app = PublicClientApplication(client_id=client, authority=authority)

    result = None
    accounts = app.get_accounts()

    if accounts:
        result = app.acquire_token_silent(scopes, account=accounts[0])

    if not result:
        result = app.acquire_token_interactive(scopes=scopes)

    if "access_token" not in result:
        raise RuntimeError(f"Failed to acquire token: {result}")

    return result


def make_session(token: Dict[str, Any]) -> requests.Session:
    """
    Builds authenticated session object.
    """
    session = requests.Session()
    session.headers.update({
        "Authorization": f"Bearer {token['access_token']}",
        "Accept": "application/json;odata=nometadata"
    })
    return session
