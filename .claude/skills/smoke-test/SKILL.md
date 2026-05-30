---
name: smoke-test
description: Lancer le smoke test Playwright qui vérifie que chacune des apps Pock charge proprement (pas d'erreur JS/console, titre attendu, rendu visible). À utiliser avant chaque PR touchant le code d'une app.
argument-hint: "[app(s) touchée(s)]"
---

# Smoke test Pock

Périmètre : **$ARGUMENTS**.

Suite Playwright légère documentée dans `tests/README.md`. Pas de CI (repo
volontairement petit) → à lancer **manuellement avant chaque PR**, ou en
pre-push hook.

## Lancer

```bash
python3 tests/smoke.py
# parcourt les 4 apps, charge chacune via file://, capture les erreurs,
# screenshots dans tests/screenshots/
```

Sort en non-zéro si une app échoue (erreur JS non catchée, erreur console,
titre manquant, rien de paintable). Voir `tests/README.md` pour l'install
de Playwright + Chromium.

## Interpréter

- **Tout vert** → safe à committer/PR.
- **Une app rouge** → ouvrir `tests/screenshots/<app>.png` + lire l'erreur
  capturée. Corriger l'app, **ne pas** « assouplir le test » sans comprendre.
  Le test charge en `file://` — une erreur de chemin relatif (asset, import)
  qui passe en HTTP peut casser ici : c'est un vrai signal de portabilité.

## Rappel
1 commit = 1 changement logique (CLAUDE.md). Si le smoke révèle un souci hors
périmètre de la PR en cours, le signaler et proposer une PR séparée — ne pas
le corriger en douce. Après une release UX, enchaîner `/release-pwa`.
