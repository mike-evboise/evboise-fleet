# main.py
# Entry point for the DayPilot SharePoint schema engine.

from dotenv import load_dotenv

# Ensure .env is loaded at process start (walks up parent dirs to find it)
load_dotenv()

import argparse
import uuid
from typing import Any, Dict

import pandas as pd

from .auth import load_environment, acquire_token, make_session
from .excel_loader import load_schema_excel
from .validators import parse_bool, validate_list_row
from .engine import process_list


def get_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="DayPilot SharePoint Schema Engine")
    parser.add_argument(
        "--dryrun",
        action="store_true",
        help="Validate schema without making changes to SharePoint.",
    )
    return parser.parse_args()


def main() -> None:
    args = get_args()

    # ============================================================
    # 1. Load .env variables
    # ============================================================
    try:
        tenant, client = load_environment()
    except Exception as e:
        print(f"\n❌ FATAL: {e}")
        return

    # ============================================================
    # 2. Authentication / DryRun
    # ============================================================
    if args.dryrun:
        print("\n🔎 DRY-RUN MODE: No SharePoint calls will be made.")
        session = None
    else:
        try:
            token = acquire_token(tenant, client)
        except Exception as e:
            print(f"\n❌ Failed to acquire token: {e}")
            return
        session = make_session(token)

    # ============================================================
    # 3. Load Excel Schema (Lists + Fields)
    # ============================================================
    try:
        df_lists, df_fields = load_schema_excel()
    except Exception as e:
        print(f"\n❌ Failed to load schema workbook: {e}")
        return

    # Convert Enabled & CreateFlag into booleans
    df_lists["Enabled_bool"] = df_lists["Enabled"].apply(parse_bool)
    df_lists["CreateFlag_bool"] = df_lists["CreateFlag"].apply(parse_bool)

    # Filter lists to process
    df_targets = df_lists[(df_lists["Enabled_bool"]) & (df_lists["CreateFlag_bool"])]

    if df_targets.empty:
        print("\n⚠️  No active lists (Enabled=TRUE and CreateFlag=TRUE).")
        return

    run_id = str(uuid.uuid4())

    print(f"\n🚀 DayPilot Schema Engine Starting")
    print(f"RunId: {run_id}")
    print(f"Lists to process: {len(df_targets)}")

    # ============================================================
    # 4. Process lists
    # ============================================================
    for _, row in df_targets.iterrows():
        list_name = str(row["ListName"]).strip()

        try:
            validate_list_row(row)

            result: Dict[str, Any] = process_list(
                session=session,
                list_row=row,
                fields_df=df_fields,
                run_id=run_id,
                dry_run=args.dryrun,
            )

            # Simple console feedback; no Excel/LOG file writes
            status = result.get("Status", "Unknown")
            msg = result.get("Message", "")
            url = result.get("ListUrl", "")
            print(f"➡️  {list_name}: {status} — {msg} {url}")

        except Exception as ex:
            print(f"❌ Error processing '{list_name}': {ex}")


if __name__ == "__main__":
    # Allow running as a module: python -m scripts.sharepoint.main
    # or, if your PYTHONPATH is set correctly, directly as a script.
    main()
