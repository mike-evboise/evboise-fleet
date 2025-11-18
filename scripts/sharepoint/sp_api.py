# sp_api.py
# Fully cleaned, warning-free SharePoint REST operations for DayPilot.

from typing import Any, Dict, List, Optional


# ---------------------------------------------------------------------------
# URL normalizer — removes accidental double slashes except after https://
# ---------------------------------------------------------------------------
def _clean_url(url: str) -> str:
    while '//' in url.replace('https://', 'https:/'):
        url = url.replace('//', '/')
        url = url.replace('https:/', 'https://')
    return url


def _print_dry(msg: str) -> None:
    print(f"[DRY RUN] {msg}")


# ---------------------------------------------------------------------------
# JSON PARSERS — supports both verbose + nometadata
# ---------------------------------------------------------------------------
def _parse_single(data: Dict[str, Any]) -> Dict[str, Any]:
    if "d" in data and isinstance(data["d"], dict):
        return data["d"]
    return data


def _parse_collection(data: Dict[str, Any]) -> List[Dict[str, Any]]:
    if "d" in data:
        data = data["d"]

    if isinstance(data, dict):
        if "results" in data and isinstance(data["results"], list):
            return data["results"]
        if "value" in data and isinstance(data["value"], list):
            return data["value"]

    if isinstance(data, list):
        return data
    return []


def _parse_created_field(data: Dict[str, Any]) -> Dict[str, Any]:
    if "d" in data:
        inner = data["d"]
        if isinstance(inner, dict):
            if "Field" in inner and isinstance(inner["Field"], dict):
                return inner["Field"]
            return inner
    return data


# ---------------------------------------------------------------------------
# LIST OPERATIONS
# ---------------------------------------------------------------------------
def get_list(session, site_url: str, title: str) -> Optional[Dict[str, Any]]:
    if session is None:
        _print_dry(f"Would check if list '{title}' exists at {site_url}")
        return None

    url = _clean_url(f"{site_url}/_api/web/lists/GetByTitle('{title}')")
    resp = session.get(url)

    if resp.status_code == 200:
        return _parse_single(resp.json())
    if resp.status_code == 404:
        return None

    raise RuntimeError(
        f"Error checking list '{title}': {resp.status_code} {resp.text}"
    )


def delete_list(session, site_url: str, list_id: str) -> None:
    if session is None:
        _print_dry(f"Would delete list {list_id}")
        return

    url = _clean_url(f"{site_url}/_api/web/lists(guid'{list_id}')")
    headers = {"IF-MATCH": "*", "X-HTTP-Method": "DELETE"}
    resp = session.post(url, headers=headers)

    if resp.status_code not in (200, 204):
        raise RuntimeError(
            f"Failed to delete list {list_id}: {resp.status_code} {resp.text}"
        )
    print(f"🗑️ List deleted: {list_id}")


def create_list(session, site_url: str, title: str, desc: str, base_template: int) -> Dict[str, Any]:
    if session is None:
        _print_dry(f"Would create list '{title}'")
        return {"Id": "00000000-0000-0000-0000-000000000000", "Title": title}

    url = _clean_url(f"{site_url}/_api/web/lists")
    payload = {
        "Title": title,
        "Description": desc or "",
        "BaseTemplate": base_template,
    }

    resp = session.post(url, json=payload)
    if resp.status_code not in (200, 201):
        raise RuntimeError(
            f"Failed to create list '{title}': {resp.status_code} {resp.text}"
        )

    data = _parse_single(resp.json())
    print(f"📋 List created: {title} (Id={data.get('Id')})")
    return data


# ---------------------------------------------------------------------------
# FIELD OPERATIONS
# ---------------------------------------------------------------------------
def get_fields(session, site_url: str, list_id: str) -> List[Dict[str, Any]]:
    if session is None:
        _print_dry(f"Would query fields for list {list_id}")
        return []

    url = _clean_url(f"{site_url}/_api/web/lists(guid'{list_id}')/fields")
    resp = session.get(url)

    if resp.status_code != 200:
        raise RuntimeError(f"Failed to query fields: {resp.status_code} {resp.text}")

    return _parse_collection(resp.json())


def update_field_hidden(session, site_url: str, list_id: str, field_id: str, hidden: bool) -> None:
    if session is None:
        _print_dry(f"Would set Hidden={hidden} for field {field_id}")
        return

    url = _clean_url(f"{site_url}/_api/web/lists(guid'{list_id}')/fields(guid'{field_id}')")
    headers = {"IF-MATCH": "*", "X-HTTP-Method": "MERGE"}
    payload = {"Hidden": hidden}

    resp = session.post(url, json=payload, headers=headers)

    if resp.status_code not in (200, 204):
        raise RuntimeError(
            f"Failed to update Hidden on {field_id}: {resp.status_code} {resp.text}"
        )


def delete_field(session, site_url: str, list_id: str, field_id: str) -> None:
    if session is None:
        _print_dry(f"Would delete field {field_id}")
        return

    url = _clean_url(f"{site_url}/_api/web/lists(guid'{list_id}')/fields(guid'{field_id}')")
    headers = {"IF-MATCH": "*", "X-HTTP-Method": "DELETE"}

    resp = session.post(url, headers=headers)
    if resp.status_code not in (200, 204):
        raise RuntimeError(
            f"Failed to delete field {field_id}: {resp.status_code} {resp.text}"
        )


def create_field(session, site_url: str, list_id: str, field_xml: str) -> Dict[str, Any]:
    if session is None:
        _print_dry(f"Would create field via CreateFieldAsXml")
        return {"Id": "00000000-0000-0000-0000-000000000000"}

    url = _clean_url(f"{site_url}/_api/web/lists(guid'{list_id}')/fields/CreateFieldAsXml")
    payload = {"parameters": {"SchemaXml": field_xml}}

    resp = session.post(url, json=payload)
    if resp.status_code not in (200, 201):
        raise RuntimeError(
            f"Failed to create field: {resp.status_code} {resp.text}"
        )

    return _parse_created_field(resp.json())


# ---------------------------------------------------------------------------
# VIEW OPERATIONS — warning-free + clean URLs
# ---------------------------------------------------------------------------
def get_default_view(session, site_url: str, list_id: str) -> Dict[str, Any]:
    if session is None:
        _print_dry("Would get DefaultView")
        return {"__metadata": {"uri": "DRYRUN://default-view"}}

    url = _clean_url(f"{site_url}/_api/web/lists(guid'{list_id}')/DefaultView")
    resp = session.get(url)

    if resp.status_code != 200:
        raise RuntimeError(
            f"Failed to get default view: {resp.status_code} {resp.text}"
        )

    return {"__metadata": {"uri": url}}


def clear_view_fields(session, view_uri: str) -> None:
    if session is None:
        _print_dry("Would clear view fields")
        return

    url = _clean_url(f"{view_uri}/ViewFields/RemoveAll()")
    resp = session.post(url)

    # SILENT SKIP — no warnings
    if resp.status_code in (200, 204, 404):
        return

    raise RuntimeError(
        f"Failed to clear view fields: {resp.status_code} {resp.text}"
    )


def add_view_field(session, view_uri: str, internal_name: str) -> None:
    if session is None:
        _print_dry(f"Would add field '{internal_name}' to view")
        return

    url = _clean_url(f"{view_uri}/ViewFields/addViewField")
    payload = {"strField": internal_name}

    resp = session.post(url, json=payload)
    if resp.status_code not in (200, 204):
        raise RuntimeError(
            f"Failed to add view field {internal_name}: {resp.status_code} {resp.text}"
        )
