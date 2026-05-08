# Nullroute

**Browser-agnostic, OS-level URL tracking parameter stripper.**

Every URL you copy carries metadata about you — where you came from, what you clicked, who sent you. Nullroute kills it before it ever leaves your clipboard. Silent. Local. Always on.

Unlike browser extensions such as ClearURLs, Nullroute operates at the **operating system clipboard level**. It works regardless of which browser, email client, Slack workspace, terminal, or application the URL came from. No extension. No browser dependency. No permissions beyond your own clipboard.

---

## How it works

Nullroute runs as a background daemon that starts at login. It polls your clipboard every 500ms. When it detects a URL, it applies the [ClearURLs](https://github.com/ClearURLs/Rules) rules database to strip tracking parameters, then silently writes the cleaned URL back. If nothing was stripped, your clipboard is untouched.

**It never makes network calls.** The rules are bundled locally at install time. The daemon has no network access and no external dependencies.

---

## Installation — macOS

### Requirements

- macOS Big Sur (11) or later
- Python 3 (ships with macOS, or via `brew install python3`)

### Install

```bash
git clone https://github.com/threatcraft-co/nullroute.git
cd nullroute
bash install.sh
```

Nullroute installs to `~/.nullroute/` and registers a LaunchAgent at `~/Library/LaunchAgents/com.threatcraft.nullroute.plist`. It will start immediately and restart automatically at every login.

### Optional: strip affiliate/referral parameters

By default, Nullroute strips tracking parameters only. Referral and affiliate tags (such as Amazon's `tag=`) are kept. To strip those too:

```bash
bash install.sh --strip-referral
```

### Uninstall

```bash
bash uninstall.sh
```

This stops the daemon, removes the LaunchAgent, and cleans up the install directory. Logs are removed at your option.

### Update rules

Nullroute's rules are bundled at install time and never auto-updated. To fetch a fresh copy of the ClearURLs rules database and verify its integrity:

```bash
bash update-rules.sh
```

This is the **only** time Nullroute touches the network, and only when you explicitly ask it to. The hash is verified before any replacement.

---

## Logs

```
~/Library/Logs/nullroute/nullroute.log       # stripped URL pairs
~/Library/Logs/nullroute/nullroute.error.log # errors
```

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
- **No dependencies** beyond Python 3 and standard library. Nothing is installed via pip.
- **Fully auditable.** The daemon is a single ~160-line Python file.
- **Local rules only.** `data.min.json` is bundled at install time and only updated when you explicitly run `update-rules.sh`.
- **Clipboard only.** Nullroute reads and writes your clipboard. It touches nothing else.
- Source is open. Read it: [`nullroute.py`](nullroute.py)

---

## Rules

Tracking rules are sourced from the [ClearURLs Rules](https://github.com/ClearURLs/Rules) project and bundled as `data.min.json`. ClearURLs rules are licensed under **LGPL-3.0**. See [NOTICES](NOTICES) for full attribution.

Nullroute is not affiliated with ClearURLs. ClearURLs is a browser extension; Nullroute is an OS-level daemon. They are independent tools that happen to share the same rules database.

---

## Contributing

Issues and pull requests welcome. If you want to suggest additional rules, please open an issue upstream at [ClearURLs/Rules](https://github.com/ClearURLs/Rules) — that way the fix benefits every tool that uses the database.

---

## License

Nullroute daemon code: **MIT License** — Copyright (c) 2025 [Threatcraft](https://threatcraft.co)

Bundled rules (`data.min.json`): **LGPL-3.0** — Copyright (c) ClearURLs Contributors

See [LICENSE](LICENSE) and [NOTICES](NOTICES).
