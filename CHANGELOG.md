# Changelog

All notable changes to Nullroute are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Nullroute uses [Semantic Versioning](https://semver.org/).

---

## [1.0.0] — 2025-05-08

### Initial macOS release

**Added**
- Headless clipboard monitoring daemon (`nullroute.py`)
- ClearURLs rules integration (`data.min.json`, LGPL-3.0)
- macOS LaunchAgent installer (`platform/macos/install.sh`)
- macOS uninstaller (`platform/macos/uninstall.sh`)
- Rules update script with SHA-256 verification (`update-rules.sh`)
- Runtime integrity check — SHA-256 of `data.min.json` verified at every startup
- ReDoS protection — all regex operations guarded with 1-second `SIGALRM` timeout
- Log sanitization — query parameters never written to disk by default
- `--strip-referral` flag to optionally remove affiliate/referral parameters
- `--no-log` flag to disable all file logging
- `--verbose` flag for full URL logging during debugging
- Restricted file permissions on install (`~/.nullroute/` mode 700, files 600)
- `SECURITY.md` with full threat model and vulnerability disclosure process

**Platform support**
- macOS Big Sur (11) and later
- Linux and Windows support planned

---

## Upcoming

- Linux: systemd user service
- Windows: Task Scheduler installer
- `.github/` CI workflow and issue templates
