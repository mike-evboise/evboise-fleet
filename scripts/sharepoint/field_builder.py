# field_builder.py

from typing import Dict

def build_field_xml(field_row: Dict) -> str:
    """
    Build SharePoint Field XML based on schema row.
    Adds normalization so that Type is case-insensitive:
        number, Number, NUMBER, int, integer → Number
    """

    display_name = field_row["DisplayName"]
    internal_name = field_row["InternalName"]
    required = str(field_row.get("Required", "")).strip().upper() == "TRUE"
    type_raw = str(field_row["Type"]).strip()

    # ------------------------------------------------------
    # NORMALIZE TYPE (fix 'number' issue)
    # ------------------------------------------------------
    type_normalized = type_raw.lower()

    type_map = {
        "number": "Number",
        "int": "Number",
        "integer": "Number",
        "float": "Number",
        "double": "Number",
        "counter": "Counter",
        "autonumber": "Counter",
        # Add other aliases as needed
    }

    # Use mapping or fall back to capitalized original
    sp_type = type_map.get(type_normalized, None)

    if sp_type is None:
        # Fallback: capitalize (Text → Text, Choice → Choice)
        sp_type = type_raw[0].upper() + type_raw[1:]

    # ------------------------------------------------------
    # BUILD BASE XML
    # ------------------------------------------------------
    xml = f'<Field Type="{sp_type}" Name="{internal_name}" DisplayName="{display_name}"'

    if required:
        xml += ' Required="TRUE"'

    xml += ">"

    # ------------------------------------------------------
    # Choice fields
    # ------------------------------------------------------
    if sp_type == "Choice":
        choices_raw = field_row.get("Choices", "")
        if choices_raw:
            xml += "<CHOICES>"
            for c in str(choices_raw).split(";"):
                xml += f"<CHOICE>{c.strip()}</CHOICE>"
            xml += "</CHOICES>"

    xml += "</Field>"

    return xml
