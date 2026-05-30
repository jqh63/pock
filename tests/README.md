# Pock tests

Lightweight Playwright smoke test suite. Validates that every Pock app
loads cleanly (no uncaught JS errors, no console errors), has its
expected title, and renders something paintable. Designed to be run
manually before a PR or as a pre-push hook — not in CI (no GitHub
Actions yet, repo is small enough that local-only is fine).

## Layout

- `smoke.py` — entry point. Iterates over the 4 apps, loads each via
  `file://`, captures errors, screenshots to `screenshots/`.
- `screenshots/` — output, gitignored. Re-generated on every run.
- `README.md` — this file.

## Run

```bash
python3 tests/smoke.py
```

Exits non-zero on any failure. Screenshots are written to
`tests/screenshots/<app>.png`.

## One-shot environment install

Requires Python 3.12+ plus Playwright with Chromium:

```bash
python3 -m pip install --user playwright
python3 -m playwright install chromium
```

The Chromium binary lives in `~/.cache/ms-playwright/` (~130 MB).

## Why file:// and not a local server

Pock apps are intentionally fully static — no `fetch`, no module
imports, no relative paths that depend on a base URL. `file://` works
identically to GitHub Pages serving and avoids the friction of a
background server in tests.

## Extending

Add a new app:
1. Drop the file at the repo root (e.g. `notes.html`).
2. Add it to the `APPS` dict in `smoke.py` with a title substring.

Add deeper assertions (interaction, localStorage, multi-step flows):
inline in `smoke.py` after the `page.goto(...)` — keep it small enough
to read in one screen. If a single app accretes more than ~30 lines of
test, split it into a sibling file (`smoke_bibliotheque.py`) that
imports the same Playwright setup.
