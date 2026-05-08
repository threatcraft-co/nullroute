# Development Disclosure

## How this project was built

Nullroute was designed, directed, and tested by a non-developer with a background in cybersecurity. The implementation was produced with substantial assistance from AI-based code generation tools.

This document exists to be transparent about that process and what it means for anyone using, auditing, or contributing to this project.

---

## What that means in practice

Every line of code in this repository was written with AI assistance. The author is not a software developer and did not write the implementation independently. The conceptual design, security requirements, architecture decisions, testing approach, and final judgments on what shipped were made by the author — but the translation of those decisions into working code was AI-assisted.

This is disclosed because:

- Security tools carry a higher standard of transparency than most software
- Users of Nullroute should be able to make an informed decision about how much trust to place in the code
- The open source community deserves honesty about how a project came to exist

---

## What was done to mitigate the risks of AI-assisted code

AI-generated code can contain subtle bugs, logical errors, or security issues that are not immediately obvious. The following steps were taken to reduce that risk:

**Security requirements were defined before implementation.** The threat model, file permission requirements, integrity check design, and log sanitization policy were specified explicitly and verified against the output.

**The code was reviewed line by line.** Every function was read, understood at a conceptual level, and verified to do what it claims before being committed.

**Security hardening was applied deliberately.** SHA-256 integrity verification, ReDoS timeout protection, owner-only file permissions, and query parameter log sanitization were each explicitly requested, implemented, and confirmed to be present and functional in the running daemon.

**The tool was tested against real URLs.** Nullroute was run against known tracking URLs and the output verified before the macOS release was published.

**The codebase was kept intentionally small.** The daemon is a single ~230-line Python file. This was a deliberate decision so that anyone can read and audit it in a few minutes without needing to trace through a large or complex codebase.

**No external dependencies were introduced.** The daemon uses only Python standard library. There are no third-party packages to audit, no supply chain to trust.

---

## What this does not mean

This disclosure is not an apology. The security properties documented in `SECURITY.md` are real and were implemented intentionally. The integrity checks run. The timeouts fire. The logs do not contain query parameters. These are not aspirational claims — they are verifiable in the source.

This disclosure also does not mean the code is untrustworthy by default. It means you should read it, which you should do with any security tool regardless of how it was written.

---

## For security researchers and contributors

If you find a vulnerability, please follow the responsible disclosure process in `SECURITY.md`. The fact that this project used AI assistance in development does not change the seriousness with which security reports will be treated.

If you are a developer who wants to contribute, your review and improvement of the codebase is genuinely welcome. Contributions from people with stronger implementation experience than the original author are not just accepted — they are encouraged.

---

## Honest assessment of risk

Anyone using Nullroute should understand:

- The code has not been independently audited by a third party
- The author cannot rule out bugs or issues that were not caught during development and testing
- AI-assisted code generation, while powerful, is not equivalent to expert human engineering reviewed over time

The recommendation is the same as for any open source security tool: read the source before trusting it with anything sensitive, and report anything that looks wrong.

---

*This file will be updated if the development process changes significantly — for example, if a formal third-party audit is conducted.*
