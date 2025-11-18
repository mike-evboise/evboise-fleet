# config.py
# Central configuration for the DayPilot SharePoint schema engine.

# Path to .env
ENV_PATH = r"C:\Users\mnc35\evboise-fleet\.env"

# Path to the Excel schema registry
SCHEMA_PATH = r"C:\Users\mnc35\evboise-fleet\scripts\sharepoint\DayPilot_SchemaRegistry.xlsx"

# SharePoint host
SHAREPOINT_HOST = "https://evboise.sharepoint.com"

# System fields that should never be deleted
SYSTEM_FIELDS = {
    "ID",
    "Title",
    "Created",
    "Modified",
    "Author",
    "Editor",
    "ContentType",
    "ContentTypeId",
    "_UIVersionString",
}
