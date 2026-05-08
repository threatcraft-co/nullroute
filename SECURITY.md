# Security Policy

## Threat model

Nullroute is a local background utility. Its threat model is narrow and intentional:

- **It never makes network calls during operation.** The daemon has no network access. Rules are bundled locally at install time.
- **It reads and writes your clipboard only.** No files outside `~/.nullroute/` and `~/Library/Logs/nullroute/` are touched.
- **It runs as your user, not root.** No elevated privileges are required or requested.
- **It is a single auditable Python file.** Read it: [`nullroute.py`](nullroute.py)

---

## Known limitations

### Hash and rules from the same origin

When you run `update-rules.sh`, both the rules file and its SHA-256 hash are fetched from `rules2.clearurls.xyz`. A compromised server could serve a malicious rules file alongside a matching forged hash, and the update script would accept it — there is currently no independent trust anchor.

**Mitigation:** If you have heightened security requirements, verify the hash manually against the upstream ClearURLs repository before running `update-rules.sh`:
- https://github.com/ClearURLs/Rules

The daemon itself performs a local integrity check at every startup against the hash stored at install time. It will refuse to start if `data.min.json` has been modified since installation.

### Clipboard polling window

The daemon polls every 500ms. There is an inherent window of up to 500ms during which a URL containing tracking parameters exists in your clipboard before being cleaned. This is a fundamental characteristic of clipboard polling and is not exploitable in any meaningful threat model for this tool.

### Log file content

By default, Nullroute logs only the scheme, host, and path of stripped URLs — query parameters are never written to disk. Query strings may contain session tokens, API keys, or other sensitive values and are intentionally excluded from logs.

If you run Nullroute with `--verbose`, full URLs including query strings are logged. Use this flag for debugging only.

### ReDoS (Regular Expression Denial of Service)

The ClearURLs rules database contains complex regex patterns. Nullroute guards all regex operations with a 1-second timeout using `SIGALRM`. If a pattern exceeds the timeout (e.g., due to a crafted URL or a tampered rules file), the match is skipped and the event is logged — the daemon continues running.

---

## File permissions

The installer enforces the following permissions:

| Path | Mode | Notes |
|---|---|---|
| `~/.nullroute/` | `700` | Owner only |
| `~/.nullroute/nullroute.py` | `700` | Owner execute only |
| `~/.nullroute/data.min.json` | `600` | Owner read only |
| `~/.nullroute/data.min.json.sha256` | `600` | Owner read only |
| `~/Library/Logs/nullroute/` | `700` | Owner only |
| `~/Library/Logs/nullroute/nullroute.log` | `600` | Owner read/write |

---

## Reporting a vulnerability

If you discover a security vulnerability in Nullroute, please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

Contact: threatcraft@proton.me

Please include:
- A description of the vulnerability
- Steps to reproduce
- Your assessment of impact and exploitability

You can expect an acknowledgement within 72 hours.

---

## Supported versions

| Version | Supported |
|---|---|
| Latest (`main`) | ✅ Yes |
| Older releases | ❌ No — please update |
