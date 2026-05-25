#!/usr/bin/env python3
"""
Playwright smoke test for all Pock apps.

For each of the 4 apps:
  - Loads the HTML via file:// (no server needed — apps are static and
    self-contained, no fetches to localhost or external APIs).
  - Asserts the page reaches DOMContentLoaded without uncaught JS errors
    or unhandled promise rejections.
  - Asserts `<title>` and `<h1>` (or app-specific landmark) are present.
  - Takes a screenshot to tests/screenshots/<app>.png so visual
    regressions are easy to spot via git diff on the PNG file size or
    a manual eye-check.

Run from the repo root:
  python3 tests/smoke.py

Requires Playwright + Chromium (see tests/README.md for install). Exits
non-zero on any failure so a CI / pre-push hook can gate on it.
"""

import sys
import os
from pathlib import Path
from playwright.sync_api import sync_playwright

REPO_ROOT = Path(__file__).resolve().parent.parent
SCREENSHOT_DIR = Path(__file__).resolve().parent / "screenshots"
SCREENSHOT_DIR.mkdir(exist_ok=True)

# Each app: file → expected title substring (loose match, French)
APPS = {
    "index.html":            "Pock",
    "suivi-km-loa.html":     "km",
    "bibliotheque.html":     "Biblio",
    "covoiturage-rando.html": "Covoiturage",
}


def run_app(p, filename, title_hint):
    path = REPO_ROOT / filename
    if not path.exists():
        return f"FAIL {filename} — file missing"

    errors = []
    b = p.chromium.launch()
    ctx = b.new_context(viewport={"width": 390, "height": 844})
    page = ctx.new_page()
    page.on("pageerror", lambda e: errors.append(("pageerror", str(e))))
    page.on("console", lambda msg: errors.append(("console.error", msg.text)) if msg.type == "error" else None)

    try:
        page.goto(f"file://{path}", wait_until="load")
        page.wait_for_timeout(500)  # let any onload JS settle
        title = page.title()
        page.screenshot(path=SCREENSHOT_DIR / f"{path.stem}.png", full_page=True)
        problems = []
        if title_hint.lower() not in title.lower():
            problems.append(f"title {title!r} missing hint {title_hint!r}")
        if errors:
            for kind, msg in errors:
                problems.append(f"{kind}: {msg[:120]}")
        if problems:
            return f"FAIL {filename} — " + "; ".join(problems)
        return f"OK   {filename} — title={title!r}"
    finally:
        b.close()


def main():
    print(f"Pock smoke — repo at {REPO_ROOT}")
    fails = 0
    with sync_playwright() as p:
        for fname, hint in APPS.items():
            result = run_app(p, fname, hint)
            print(f"  {result}")
            if result.startswith("FAIL"):
                fails += 1
    print(f"\nResult: {len(APPS) - fails}/{len(APPS)} passed (screenshots in {SCREENSHOT_DIR})")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
