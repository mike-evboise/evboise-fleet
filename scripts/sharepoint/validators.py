# validators.py
# Validates Excel schema rows for the SharePoint engine.

from typing import Any
import pandas as pd


def fatal(msg: str):
    raise ValueError(msg)


def parse_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    if value is None:
        return False

    v = str(value).strip().lower()
    return v in ("true", "yes", "1", "y")


def parse_int(value: Any, default: int | None = None) -> int | None:
    if value is None or value == "":
        return default
    try:
        return int(value)
    except Exception:
        return default


def validate_list_row(list_name_row: pd.Series):
    if not str(list_name_row.get("ListName", "")).strip():
        fatal("List row missing ListName")
    if not str(list_name_row.get("SiteURL", "")).strip():
        fatal(f"List '{list_name_row.get('ListName')}' missing SiteURL")


def validate_field_rows(list_name: str, fields_df: pd.DataFrame) -> pd.DataFrame:
    """
    Returns only fields belonging to this list.
    Performs required-column validation.
    DOES NOT validate NumLines anymore.
    """

    required_cols = [
        "ListName",
        "InternalName",
        "DisplayName",
        "Type",
        "Description",
        "Required",
        "ReadOnly",
        "Hidden",
        "Choices",
        "NumLines",       # required column, but no validation
        "Indexed",
        "DefaultValue",
        "XMLOverride",
        "Visible",
        "Order",
    ]

    for col in required_cols:
        if col not in fields_df.columns:
            fatal(f"Fields sheet missing required column '{col}'")

    # Filter rows for this list
    rows = fields_df[fields_df["ListName"] == list_name]

    if rows.empty:
        fatal(f"Fields sheet contains no rows for list '{list_name}'")

    # No NumLines validation here — IGNORE COMPLETELY

    # Sort by Order if present, else preserve Excel row order
    if "Order" in rows.columns and rows["Order"].notna().any():
        rows = rows.sort_values(by="Order", ascending=True)

    return rows.reset_index(drop=True)
