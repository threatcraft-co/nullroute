# Nullroute

![ci](https://github.com/threatcraft-co/nullroute/actions/workflows/ci.yml/badge.svg)

> Before use, please consider reading [`DEVELOPMENT_TRANSPARENCY.md`](DEVELOPMENT_TRANSPARENCY.md) for full disclosure on how this tool was produced and what that means for how you should evaluate it.

**Browser-agnostic, OS-level URL tracking parameter stripper.**

Every URL you copy carries metadata about you — where you came from, what you clicked, who sent you. Nullroute kills it before it ever leaves your clipboard. Silent. Local. Always on.

Unlike browser extensions such as ClearURLs, Nullroute operates at the **operating system clipboard level**. It works regardless of which browser, email client, Slack workspace, terminal, or application the URL came from. No extension. No browser dependency. No permissions beyond your own clipboard.

---

## How it works

Nullroute runs as a background daemon that starts at login. It polls your clipboard every 500ms. When it detects a URL, it applies the [ClearURLs](https://github.com/ClearURLs/Rules) rules database to strip tracking parameters, then silently writes the cleaned URL back. If nothing was stripped, your clipboard is untouched.

**It never makes network calls.** The rules are bundled locally at install time. The daemon verifies the integrity of the rules file on every startup. No network access. No external dependencies.

---

## Installation — macOS

### Requirements

- macOS Big Sur (11) or later
- Python 3 (ships with macOS, or via `brew install python3`)

### Install

```bash
git clone https://github.com/threatcraft-co/nullroute.git
cd nullroute
bash platform/macos/install.sh
```

Nullroute installs to `~/.nullroute/` and registers a LaunchAgent at `~/Library/LaunchAgents/com.threatcraft.nullroute.plist`. It will start immediately and restart automatically at every login.

### Optional flags

```bash
# Also strip affiliate/referral parameters (e.g. Amazon tag=)
bash platform/macos/install.sh --strip-referral

# Disable all file logging
bash platform/macos/install.sh --no-log

# Log full URLs for debugging (default: domain+path only)
bash platform/macos/install.sh --verbose
```

### Uninstall

```bash
bash platform/macos/uninstall.sh
```

Stops the daemon, removes the LaunchAgent, and cleans up the install directory. Logs are removed at your option.

### Update rules

Nullroute's rules are bundled at install time and never auto-updated. To fetch a fresh copy of the ClearURLs rules database and verify its integrity:

```bash
bash update-rules.sh
```

This is the **only** time Nullroute touches the network, and only when you explicitly ask it to. The hash is verified before any replacement.

---

## Logs

```
~/Library/Logs/nullroute/nullroute.log       # stripped URL events (domain+path only)
~/Library/Logs/nullroute/nullroute.error.log # errors
```

Query parameters are never written to logs by default. See `SECURITY.md` for details.

---

## Platform support

| Platform | Status | Method |
|---|---|---|
| macOS | ✅ Supported | LaunchAgent + `pbpaste`/`pbcopy` |
| Linux | 🔜 Planned | systemd user service + `xclip`/`wl-clipboard` |
| Windows | 🔜 Planned | Task Scheduler + `clip`/PowerShell |

---

## Security and privacy

- **Zero network calls** during normal operation. The daemon has no network access.
- **Integrity verified at startup.** The rules file is SHA-256 checked against a hash stored at install time. The daemon refuses to start if the file has been modified.
- **ReDoS protected.** All regex operations are guarded with a hard 1-second timeout.
- **No dependencies** beyond Python 3 and standard library. Nothing installed via pip.
- **Fully auditable.** The daemon is a single Python file. Read it: [`nullroute.py`](nullroute.py)
- **Clipboard only.** Nullroute reads and writes your clipboard. It touches nothing else.

See [`SECURITY.md`](SECURITY.md) for the full threat model, known limitations, and vulnerability reporting.

---

## Rules

Tracking rules are sourced from the [ClearURLs Rules](https://github.com/ClearURLs/Rules) project and bundled as `data.min.json`. ClearURLs rules are licensed under **LGPL-3.0**. See [NOTICES](NOTICES) for full attribution.

Nullroute is not affiliated with ClearURLs. ClearURLs is a browser extension; Nullroute is an OS-level daemon. They are independent tools that share the same rules database.

---

## Contributing

Issues and pull requests are welcome. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a PR.

To suggest new tracking parameters, open an issue upstream at [ClearURLs/Rules](https://github.com/ClearURLs/Rules) — that way the fix benefits every tool using the database.

---

## License

Nullroute daemon code: **MIT License** — Copyright (c) 2025 [Threatcraft](https://threatcraft.co)

Bundled rules (`data.min.json`): **LGPL-3.0** — Copyright (c) ClearURLs Contributors

See [LICENSE](LICENSE) and [NOTICES](NOTICES).
