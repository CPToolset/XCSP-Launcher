#!/usr/bin/env python3
import sys
import re
from pathlib import Path
from loguru import logger

def update_file(path: Path, pattern: str, replacement: str):
    text = path.read_text()
    new_text, count = re.subn(pattern, replacement, text)
    if count == 0:
        logger.warning(f"No matches found in {path} for pattern: {pattern}")
    else:
        logger.success(f"Updated {count} occurrence(s) in {path}")
        path.write_text(new_text)

def main():
    if len(sys.argv) != 2:
        logger.error("Usage: python update_metadata.py <new_version>")
        sys.exit(1)

    version = sys.argv[1]

    root = Path(__file__).resolve().parent.parent

    # Update snapcraft.yaml
    snap_path = root / "snap" / "snapcraft.yaml"
    update_file(
        snap_path,
        r"(?<=^version:\s*)['\"]?[\w\.\-]+['\"]?",
        f"'{version}'"
    )

    # Update chocolatey nuspec
    nuspec_path = root / "chocolatey" / "xcsp-launcher.nuspec"
    update_file(
        nuspec_path,
        r"<version>[\w\.\-]+</version>",
        f"<version>{version}</version>"
    )

if __name__ == "__main__":
    main()
