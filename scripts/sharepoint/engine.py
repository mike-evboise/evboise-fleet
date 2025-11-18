# engine.py

from typing import Any, Dict
from . import sp_api as sp
from .field_builder import build_field_xml


def _resolve_column(row, name: str) -> Any:
    key = name.strip().lower()
    normalized = {col.strip().lower(): col for col in row.index}

    if key not in normalized:
        raise KeyError(
            f"Column '{name}' not found. Present columns: {list(row.index)}"
        )

    return row[normalized[key]]


def process_list(
    session,
    list_row,
    fields_df,
    run_id: str,
    dry_run: bool,
) -> Dict[str, Any]:

    # Normalize site URL (remove trailing slash)
    site_url = str(_resolve_column(list_row, "SiteUrl")).rstrip("/")

    list_name = list_row["ListName"]
    desc = list_row.get("Description", "") or ""

    base_template_raw = list_row.get("BaseTemplate", 100)
    try:
        base_template = int(str(base_template_raw).strip())
    except:
        base_template = 100

    print("\n==============================")
    print(f"▶ Processing list: {list_name}")
    print(f"   Site: {site_url}")
    print("==============================")

    # ------------------------------------------------------
    # Check if list exists
    # ------------------------------------------------------
    existing = sp.get_list(session, site_url, list_name)

    if existing:
        choice = input(
            f"⚠️  List '{list_name}' already exists. Overwrite? Type YES to continue: "
        ).strip()

        if choice.lower() != "yes":
            print(f"❌ {list_name}: Skipped — User declined overwrite.")
            return {
                "Status": "Skipped",
                "Message": "User declined overwrite.",
                "ListUrl": existing.get("DefaultViewUrl", ""),
            }

        sp.delete_list(session, site_url, existing["Id"])

    # ------------------------------------------------------
    # Create list
    # ------------------------------------------------------
    created = sp.create_list(
        session=session,
        site_url=site_url,
        title=list_name,
        desc=desc,
        base_template=base_template,
    )

    list_id = created["Id"]

    # ------------------------------------------------------
    # Get default view
    # ------------------------------------------------------
    view_info = sp.get_default_view(session, site_url, list_id)
    view_uri = view_info["__metadata"]["uri"]

    # ------------------------------------------------------
    # Create fields
    # ------------------------------------------------------
    field_rows = fields_df[fields_df["ListName"] == list_name]

    for _, field in field_rows.iterrows():
        xml = build_field_xml(field)
        created_field = sp.create_field(
            session=session,
            site_url=site_url,
            list_id=list_id,
            field_xml=xml,
        )
        field_id = created_field["Id"]

        hidden = str(field.get("Hidden", "")).strip().upper() == "TRUE"
        if hidden:
            sp.update_field_hidden(
                session=session,
                site_url=site_url,
                list_id=list_id,
                field_id=field_id,
                hidden=True,
            )

    # ------------------------------------------------------
    # Reset view fields silently
    # ------------------------------------------------------
    sp.clear_view_fields(session, view_uri)

    # ------------------------------------------------------
    # Add visible fields back to the view
    # ------------------------------------------------------
    for _, field in field_rows.iterrows():
        internal = field["InternalName"]
        show = str(field.get("ShowInView", "")).strip().upper() != "FALSE"
        if show:
            sp.add_view_field(session, view_uri, internal)

    # ------------------------------------------------------
    # Success
    # ------------------------------------------------------
    return {
        "Status": "OK",
        "Message": "List processed successfully.",
        "ListUrl": f"{site_url}/Lists/{list_name}/AllItems.aspx",
    }
