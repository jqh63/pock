# Pock

Pocket tools — lightweight personal web apps that run offline in any browser.

No backend, no framework, no external dependencies. Just HTML/CSS/JS + system fonts.

## Apps

### 🚗 Suivi km LOA

Track mileage against your lease (LOA) allowance. Add your own vehicles, log odometer readings, and see at a glance whether you're under or over budget.

- Pre-configured with two example vehicles
- Add/remove vehicles with custom name, color, start date, duration, km/year, and excess cost/km
- Dashboard: current km, delta vs expected, remaining budget per month
- Cost projection with stability threshold (needs 2+ readings and 14+ days of data before projecting)
- SVG chart: expected vs actual mileage curve
- Contract status: not started, active, or ended
- Reset entries while keeping vehicle config
- All vehicle configs and readings stored in localStorage

### 📚 Ma Bibliothèque

Track your reading list, library reservations, and borrowed books. Filter by status, search by title or author, import books in bulk.

- Statuses: to read, reading, read, reserved, borrowed
- Quick status change, edit, delete (with confirmation)
- Bulk import (paste a list: title ; author ; note)
- Sort by date, title, or author (stable sort)
- Persistent history in localStorage

### 🥾 Covoiturage Rando

Calculate fair cost-sharing for group hiking carpools at €0.30/km. Handles multiple cars, rounds up to the nearest euro, shows any surplus for the club fund.

- Detailed cost breakdown
- Backup rate table for offline use without the app
- Persistent history of last 20 calculations

### 💾 Data export / import

From the hub, export all your Pock data to a single JSON file, or import back. Supports merge or replace modes. Useful for backup or switching devices.

## Install

### GitHub Pages

1. Fork or push to a GitHub repo
2. **Settings → Pages → Source: main branch**
3. Access at `https://<username>.github.io/<repo>/`

### Local

Open `index.html` in any browser. No server needed.

### As a mobile app (PWA)

Visit the site on your phone, then:
- **Android**: tap the install banner or Menu → "Add to Home Screen"
- **iOS**: Share → "Add to Home Screen"

The app works offline after first visit.

## Compatibility

Chrome, Safari, Firefox — Android, iOS, Windows, macOS.

## Files (flat, all at repo root)

```
index.html              ← Hub + data export/import
suivi-km-loa.html       ← Mileage tracker
covoiturage-rando.html  ← Carpooling calculator
bibliotheque.html       ← Book tracker
common.css              ← Shared base styles (reset, tokens, focus)
common.js               ← Shared helpers (esc, genId, SW reg, export/import)
manifest.json           ← PWA manifest
sw.js                   ← Service worker (offline, cache-first)
icon-192.png            ← Standard icon
icon-512.png            ← Large icon
icon-maskable.png       ← Maskable icon
apple-touch-icon.png    ← iOS home screen (180px)
```

## Data & Privacy

All data stays in your browser's localStorage. Nothing is sent to any server.

Storage keys used:
- `pock-km-vehicles` — vehicle configurations
- `pock-km-[id]` — mileage entries per vehicle
- `pock-km-active` — last selected vehicle
- `pock-biblio-books` — book collection
- `pock-covoit-history` — carpooling history

## License

MIT — fork it, adapt it, make it yours.
