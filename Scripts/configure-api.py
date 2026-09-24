#!/usr/bin/env python3
"""Copy the local API token into an ignored app configuration file."""

import os
from pathlib import Path
import plistlib

root = Path(__file__).resolve().parents[1]
token = os.environ.get("CATALOG_API_TOKEN", "").strip()
source = root / ".env.local"
if not token and source.exists():
    for line in source.read_text().splitlines():
        key, separator, value = line.partition("=")
        if separator and key.strip() == "CATALOG_API_TOKEN":
            token = value.strip().strip("\"'")
            break

if not token:
    raise SystemExit("Set CATALOG_API_TOKEN in .env.local or in your environment first.")

destination = root / "SoleraIOSChallenge/SoleraIOSChallenge/APIConfiguration.local.plist"
destination.write_bytes(plistlib.dumps({"token": token}))
destination.chmod(0o600)
print("Local API configuration is ready. Rebuild the app to use it.")
