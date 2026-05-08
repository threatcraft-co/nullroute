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

Nullroute is not affiliated with ClearURLs or any browser extension.
This tool operates at the OS clipboard level, independent of any browser.
"""

import argparse
import hashlib
import json
import logging
import re
import signal
import subprocess
import sys
import time
from pathlib import Path
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

POLL_INTERVAL   = 0.5   # seconds between clipboard checks
REGEX_TIMEOUT   = 1     # seconds before a regex match is aborted (ReDoS guard)
LOG_URL_MAXLEN  = 80    # max chars of domain+path written to log

RULES_PATH      = Path(__file__).parent / "data.min.json"
HASH_PATH       = Path(__file__).parent / "data.min.json.sha256"
LOG_DIR         = Path.home() / "Library" / "Logs" / "nullroute"

# Set True to also strip referral/affiliate parameters (e.g. Amazon 'tag=')
STRIP_REFERRAL_MARKETING = False


# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="nullroute",
        description="Browser-agnostic OS-level URL tracking stripper"
    )
    parser.add_argument(
        "--no-log",
        action="store_true",
        help="Disable all file logging (nothing is written to disk)"
    )
    parser.add_argument(
        "--strip-referral",
        action="store_true",
        help="Also strip affiliate/referral parameters (e.g. Amazon tag=)"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Log full URLs for debugging (default: domain+path only)"
    )
    return parser.parse_args()


# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

def setup_logging(no_log: bool = False) -> None:
    if no_log:
        logging.disable(logging.CRITICAL)
        return
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    # Restrict log file permissions to owner only
    log_file = LOG_DIR / "nullroute.log"
    log_file.touch(mode=0o600, exist_ok=True)
    logging.basicConfig(
        filename=str(log_file),
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


def sanitize_url_for_log(url: str) -> str:
    """
    Return only the scheme + host + path of a URL for logging.
    Query parameters and fragments are intentionally omitted — they may
    contain session tokens, API keys, or other sensitive values.
    """
    try:
        parsed = urlparse(url)
        safe = f"{parsed.scheme}://{parsed.netloc}{parsed.path}"
        return safe[:LOG_URL_MAXLEN]
    except Exception:
        return "[unparseable url]"


# ---------------------------------------------------------------------------
# Rules integrity
# ---------------------------------------------------------------------------

def compute_sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def verify_rules_integrity() -> None:
    """
    Verify data.min.json against its stored SHA-256 hash before loading.
    Exits with a clear error if the file is missing, unverifiable, or
    has been tampered with since install/last update.
    """
    if not RULES_PATH.exists():
        print(
            f"[nullroute] ERROR: Rules file not found: {RULES_PATH}",
            file=sys.stderr
        )
        sys.exit(1)

    if not HASH_PATH.exists():
        print(
            f"[nullroute] ERROR: Integrity hash not found: {HASH_PATH}\n"
            f"  Re-run the installer or update-rules.sh to generate it.",
            file=sys.stderr
        )
        sys.exit(1)

    expected = HASH_PATH.read_text().strip().lower()
    actual   = compute_sha256(RULES_PATH)

    if actual != expected:
        print(
            f"[nullroute] SECURITY ERROR: data.min.json integrity check failed.\n"
            f"  Expected: {expected}\n"
            f"  Got:      {actual}\n"
            f"  The rules file may have been tampered with.\n"
            f"  Run update-rules.sh to restore a verified copy.",
            file=sys.stderr
        )
        sys.exit(1)


def load_rules() -> dict:
    """Load and return the ClearURLs provider rules from data.min.json."""
    with open(RULES_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    providers = data.get("providers", {})
    logging.info("Loaded %d providers from rules (integrity verified)", len(providers))
    return providers


# ---------------------------------------------------------------------------
# ReDoS protection
# ---------------------------------------------------------------------------

class _RegexTimeout(Exception):
    pass


def _alarm_handler(signum, frame):
    raise _RegexTimeout()


def safe_regex_search(pattern: str, string: str, flags: int = 0) -> object:
    """
    re.search with a hard timeout to prevent catastrophic backtracking.
    Returns None on timeout or regex error rather than hanging.
    Uses SIGALRM — Unix/macOS only, must be called from the main thread.
    """
    old_handler = signal.signal(signal.SIGALRM, _alarm_handler)
    signal.alarm(REGEX_TIMEOUT)
    try:
        return re.search(pattern, string, flags)
    except _RegexTimeout:
        logging.warning("Regex timeout on pattern (possible ReDoS): %.60s", pattern)
        return None
    except re.error:
        return None
    finally:
        signal.alarm(0)
        signal.signal(signal.SIGALRM, old_handler)


def safe_regex_sub(pattern: str, repl: str, string: str, flags: int = 0) -> str:
    """re.sub with timeout. Returns original string on timeout or error."""
    old_handler = signal.signal(signal.SIGALRM, _alarm_handler)
    signal.alarm(REGEX_TIMEOUT)
    try:
        return re.sub(pattern, repl, string, flags=flags)
    except _RegexTimeout:
        logging.warning("Regex timeout on sub pattern (possible ReDoS): %.60s", pattern)
        return string
    except re.error:
        return string
    finally:
        signal.alarm(0)
        signal.signal(signal.SIGALRM, old_handler)


def safe_regex_fullmatch(pattern: str, string: str, flags: int = 0) -> object:
    """re.fullmatch with timeout. Returns None on timeout or error."""
    old_handler = signal.signal(signal.SIGALRM, _alarm_handler)
    signal.alarm(REGEX_TIMEOUT)
    try:
        return re.fullmatch(pattern, string, flags)
    except _RegexTimeout:
        logging.warning("Regex timeout on fullmatch (possible ReDoS): %.60s", pattern)
        return None
    except re.error:
        return None
    finally:
        signal.alarm(0)
        signal.signal(signal.SIGALRM, old_handler)


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


def clean_url(url: str, providers: dict, strip_referral: bool = False) -> str:
    """
    Apply ClearURLs provider rules to strip tracking parameters from a URL.

    For each provider:
      1. Skip if URL does not match urlPattern.
      2. Skip if URL matches any exception pattern.
      3. Apply rawRules (regex substitutions on the full URL string).
      4. Strip query parameters matching any rule pattern.
      5. Optionally strip referralMarketing parameters.

    All regex operations are guarded against catastrophic backtracking.
    Returns the cleaned URL, or the original if no changes were made.
    """
    for _name, provider in providers.items():

        # 1. Check provider pattern
        pattern = provider.get("urlPattern", "")
        if not safe_regex_search(pattern, url, re.IGNORECASE):
            continue

        # 2. Check exceptions — skip this provider if URL is excepted
        skip = False
        for exc in provider.get("exceptions", []):
            if safe_regex_search(exc, url, re.IGNORECASE):
                skip = True
                break
        if skip:
            continue

        # 3. Apply rawRules (e.g. strip /ref=... from Amazon URLs)
        for raw_rule in provider.get("rawRules", []):
            url = safe_regex_sub(raw_rule, "", url, flags=re.IGNORECASE)

        # 4. Strip matching query parameters
        parsed = urlparse(url)
        if parsed.query:
            params = parse_qs(parsed.query, keep_blank_values=True)

            rules_to_apply = list(provider.get("rules", []))
            if strip_referral:
                rules_to_apply += provider.get("referralMarketing", [])

            cleaned_params = {}
            for key, val in params.items():
                stripped = any(
                    safe_regex_fullmatch(rule, key, re.IGNORECASE)
                    for rule in rules_to_apply
                )
                if not stripped:
                    cleaned_params[key] = val

            new_query = urlencode(cleaned_params, doseq=True)
            url = urlunparse(parsed._replace(query=new_query))

        # Remove trailing bare '?' if all params were stripped
        if url.endswith("?"):
            url = url[:-1]

    return url


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

def run() -> None:
    args = parse_args()

    strip_referral = args.strip_referral or STRIP_REFERRAL_MARKETING

    setup_logging(no_log=args.no_log)

    logging.info("Nullroute starting")

    # Verify rules file integrity before loading
    verify_rules_integrity()

    try:
        providers = load_rules()
    except json.JSONDecodeError as e:
        logging.error("Failed to parse rules file: %s", e)
        print(f"[nullroute] ERROR: Failed to parse rules file: {e}", file=sys.stderr)
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

            cleaned = clean_url(content.strip(), providers, strip_referral)

            if cleaned != content.strip():
                set_clipboard(cleaned)
                last_clipboard = cleaned

                if args.verbose:
                    # Full URLs only when explicitly requested
                    logging.info("Stripped: %s", content.strip()[:200])
                    logging.info("      → : %s", cleaned[:200])
                else:
                    # Default: log domain+path only, never query params
                    logging.info(
                        "Stripped tracking params from: %s",
                        sanitize_url_for_log(content.strip())
                    )

        except KeyboardInterrupt:
            logging.info("Nullroute stopped by user")
            sys.exit(0)
        except Exception as e:
            logging.error("Unexpected error: %s", e)

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    run()
