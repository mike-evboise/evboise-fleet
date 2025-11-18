# excel_loader.py
# Load the Excel schema registry WITHOUT writing anything back to it.

import os
import sys
import pandas as pd
from .config import SCHEMA_PATH


def fatal(msg: str) -> None:
    print(f"\n❌ FATAL: {msg}")
    sys.exit(1)


def load_schema_excel():
    """
    Loads ONLY the schema sheets (Lists, Fields).
    DOES NOT load or save any ExecutionLog.
    """
    if not os.path.exists(SCHEMA_PATH):
        fatal(f"Schema registry not found at {SCHEMA_PATH}")

    print(f"\n📄 Loading schema from: {SCHEMA_PATH}")
    xl = pd.ExcelFile(SCHEMA_PATH)

    try:
        df_lists = xl.parse("Lists").fillna("")
        df_fields = xl.parse("Fields").fillna("")
    except ValueError as e:
        fatal(f"Missing required sheet in Excel: {e}")

    print("✅ Schema workbook loaded")
    return df_lists, df_fields
