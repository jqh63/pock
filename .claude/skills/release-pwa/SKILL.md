---
name: release-pwa
description: Publier une version de Pock — bumper le marqueur visuel et la version CACHE du service worker pour déclencher l'auto-update PWA chez les utilisateurs installés. À utiliser à chaque release qui change l'UX. Oublier le bump CACHE = clients installés bloqués sur l'ancienne version.
argument-hint: "[X.Y - ce qui change]"
---

# Publier une version Pock

Release : **$ARGUMENTS**.

GitHub Pages est la prod — pas de staging. Le service worker (`sw.js`) cache
l'app, donc un changement d'UX n'atteint les utilisateurs **installés** que si
la version `CACHE` est bumpée. Cf. CLAUDE.md § *Versioning et propagation*.

## Étapes

1. **Bumper les deux marqueurs** (les garder synchrones) :
   - `index.html` (footer) → marqueur visuel `vX.Y`
   - `sw.js` → `const CACHE_NAME = 'pock-vX.Y'`
   ```bash
   grep -n "CACHE_NAME" sw.js
   grep -nE 'v[0-9]+\.[0-9]+' index.html | head
   ```

2. **Bumper à chaque release qui change l'UX.** Un changement doc-only ne
   nécessite pas de bump CACHE. En cas de doute, bumper — un bump superflu ne
   coûte qu'un cycle d'update ; un bump oublié bloque silencieusement les
   clients installés.

3. **Multi-app** : Pock sert plusieurs apps (bibliotheque, covoiturage-rando,
   suivi-km-loa…) derrière un seul `sw.js`. Vérifier que le changement et le
   bump couvrent bien l'app touchée, et que `sw.js` précache la liste à jour.

4. **PR** : commit conventional FR à l'impératif (pas de scope), identité
   noreply. `gh pr create` → `gh pr merge --merge --delete-branch` (pas de
   squash).

5. **Vérifier après merge** sur l'URL publique (pas de staging) : hard-reload,
   confirmer le nouveau marqueur de version, et qu'un client installé se met à
   jour. Avant la PR, passer `/smoke-test` (les 4 apps doivent charger propre).

## Garde-fou
Aucune donnée perso / secret dans le diff (repo public) — placeholders only.
Le hook pre-commit-secret-scan bloque les secrets à forme complète.
