#!/usr/bin/env python3
"""
Nullroute — Browser and OS agnostic URL tracking parameter stripper
https://github.com/threatcraft-co/nullroute

Daemon code: MIT License
Copyright (c) 2025 Threatcraft (Isabella San Lorenzo)
https://threatcraft.co

Bundled rules (data.min.json): LGPL-3.0
Copyright (c) ClearURLs Contributors
https://github.com/ClearURLs/Rules

URLClean rules concept credited to the ClearURLs project.
Nullroute is not affiliated with ClearURLs or any browser extension.
This tool operates at the OS clipboard level, independent of any browser.
"""

import json
import logging
import re
import subprocess
import sys
import time
from pathlib import Path
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

POLL_INTERVAL = 0.5  # seconds between clipboard checks
RULES_PATH = Path(__file__).parent / "data.min.json"
LOG_DIR = Path.home() / "Library" / "Logs" / "nullroute"

# Set True to also strip referral/affiliate parameters (e.g. Amazon 'tag=')
# These are tracked separately in the ClearURLs rules set.
STRIP_REFERRAL_MARKETING = False


# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

def setup_logging() -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_file = LOG_DIR / "nullroute.log"
    logging.basicConfig(
        filename=str(log_file),
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


# ---------------------------------------------------------------------------
# Rules
# ---------------------------------------------------------------------------

def load_rules() -> dict:
    """Load and return the ClearURLs provider rules from data.min.json."""
    with open(RULES_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    providers = data.get("providers", {})
    logging.info("Loaded %d providers from rules", len(providers))
    return providers


# ---------------------------------------------------------------------------
# Clipboard (macOS)
# ---------------------------------------------------------------------------

def get_clipboard() -> str:
    result = subprocess.run(
        ["pbpaste"],
        capture_output=True,
        text=True
    )
    return result.stdout


def set_clipboard(text: str) -> None:
    subprocess.run(
        ["pbcopy"],
        input=text,
        text=True
    )


# ---------------------------------------------------------------------------
# URL cleaning engine
# ---------------------------------------------------------------------------

def is_url(text: str) -> bool:
    t = text.strip()
    return t.startswith("http://") or t.startswith("https://")


def clean_url(url: str, providers: dict) -> str:
    """
    Apply ClearURLs provider rules to strip tracking parameters from a URL.

    For each provider:
      1. Skip if URL does not match urlPattern.
      2. Skip if URL matches any exception pattern.
      3. Apply rawRules (regex substitutions on the full URL string).
      4. Strip query parameters matching any rule pattern.
      5. Optionally strip referralMarketing parameters.

    Returns the cleaned URL, or the original if no changes were made.
    """
    for _name, provider in providers.items():

        # 1. Check provider pattern
        pattern = provider.get("urlPattern", "")
        try:
            if not re.search(pattern, url, re.IGNORECASE):
                continue
        except re.error:
            continue

        # 2. Check exceptions
        skip = False
        for exc in provider.get("exceptions", []):
            try:
                if re.search(exc, url, re.IGNORECASE):
                    skip = True
                    break
            except re.error:
                continue
        if skip:
            continue

        # 3. Apply rawRules (e.g. strip /ref=... from Amazon URLs)
        for raw_rule in provider.get("rawRules", []):
            try:
                url = re.sub(raw_rule, "", url, flags=re.IGNORECASE)
            except re.error:
                continue

        # 4. Strip matching query parameters
        parsed = urlparse(url)
        if parsed.query:
            params = parse_qs(parsed.query, keep_blank_values=True)

            rules_to_apply = list(provider.get("rules", []))
            if STRIP_REFERRAL_MARKETING:
                rules_to_apply += provider.get("referralMarketing", [])

            cleaned_params = {}
            for key, val in params.items():
                strip = False
                for rule in rules_to_apply:
                    try:
                        if re.fullmatch(rule, key, re.IGNORECASE):
                            strip = True
                            break
                    except re.error:
                        continue
                if not strip:
                    cleaned_params[key] = val

            new_query = urlencode(cleaned_params, doseq=True)
            url = urlunparse(parsed._replace(query=new_query))

        # Remove a trailing bare '?' if all params were stripped
        if url.endswith("?"):
            url = url[:-1]

    return url


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

def run() -> None:
    setup_logging()
    logging.info("Nullroute starting")

    try:
        providers = load_rules()
    except FileNotFoundError:
        logging.error("Rules file not found: %s", RULES_PATH)
        sys.exit(1)
    except json.JSONDecodeError as e:
        logging.error("Failed to parse rules file: %s", e)
        sys.exit(1)

    last_clipboard = None

    logging.info("Nullroute running — monitoring clipboard")

    while True:
        try:
            content = get_clipboard()

            # Skip if clipboard unchanged
            if content == last_clipboard:
                time.sleep(POLL_INTERVAL)
                continue

            last_clipboard = content

            # Skip non-URLs
            if not is_url(content):
                time.sleep(POLL_INTERVAL)
                continue

            cleaned = clean_url(content.strip(), providers)

            if cleaned != content.strip():
                set_clipboard(cleaned)
                last_clipboard = cleaned
                # Truncate for log readability
                orig_short = content.strip()[:120]
                clean_short = cleaned[:120]
                logging.info("Stripped: %s", orig_short)
                logging.info("      → : %s", clean_short)

        except KeyboardInterrupt:
            logging.info("Nullroute stopped by user")
            sys.exit(0)
        except Exception as e:
            logging.error("Unexpected error: %s", e)

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    run()
