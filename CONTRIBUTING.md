# Contributing to Nullroute

Thanks for your interest in contributing. Nullroute is a small, focused tool — contributions that keep it small and focused are most welcome.

---

## What kind of contributions are useful

**Bug reports** — if Nullroute breaks something, strips something it shouldn't, or fails to start, please open an issue with the error output and your macOS version.

**Platform ports** — Linux and Windows support are planned. If you want to take a platform on, open an issue first so we can align on the approach before you write code.

**Security issues** — please do not open a public issue. See [`SECURITY.md`](SECURITY.md) for responsible disclosure.

**Rule suggestions** — if a tracking parameter isn't being stripped, the right place to report it is upstream at [ClearURLs/Rules](https://github.com/ClearURLs/Rules). Nullroute pulls from their database, so a fix there benefits every tool that uses it, not just Nullroute.

---

## What to avoid

- Adding dependencies. Nullroute has zero runtime dependencies beyond Python 3 stdlib. Please keep it that way — it's a feature, not a gap.
- Network calls in the daemon. The daemon must never make network calls. This is a hard constraint.
- UI. Nullroute is headless by design.

---

## Development setup

No build system or virtual environment required. The daemon is a single Python file.

```bash
git clone https://github.com/threatcraft-co/nullroute.git
cd nullroute
python3 nullroute.py
```

To run against a local rules file during development, edit `RULES_PATH` at the top of `nullroute.py` temporarily.

---

## Pull request checklist

- [ ] Tested on your target platform
- [ ] No new dependencies introduced
- [ ] No network calls added to the daemon
- [ ] File permissions preserved or tightened (never loosened)
- [ ] `CHANGELOG.md` updated under `## Upcoming`
- [ ] Commit messages are lowercase and descriptive (`fix: ...`, `feat: ...`, `chore: ...`)

---

## Code style

- Python: standard library only, type hints on function signatures, docstrings on public functions
- Shell: `set -euo pipefail`, no `eval`, no unquoted variables
- Keep it readable — this codebase is meant to be auditable by anyone in five minutes

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
