#!/bin/bash
# Hook PreToolUse : bloque un `git commit` si le diff staged contient un
# secret a HAUTE CONFIANCE (forme complete de cle, pas un simple prefixe).
#
# Choix volontaire : on ne matche QUE des formes completes (prefixe +
# entropie suffisante) pour ne PAS bloquer les fichiers de doc du repo qui
# citent les prefixes nus (sk-, ghp_, Bearer) en exemple. Pour un audit
# plus large (mots de passe en clair, IP publique, *_TOKEN non ${VAR}),
# deleguer au subagent `secret-scanner`.
#
# exit 0 = laisse passer / non concerne ; exit 2 = bloque le commit.

INPUT=$(cat)

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
# Ne s'active que sur un git commit
echo "$CMD" | grep -qE '\bgit\b.*\bcommit\b' || exit 0

DIFF=$(git diff --cached 2>/dev/null)
[ -z "$DIFF" ] && exit 0

# Formes completes uniquement (les prefixes nus en doc ne matchent pas) :
# - ghp_/gho_ + 36, github_pat_ + long  (GitHub PAT)
# - sk-ant- + long, sk- + 40+           (Anthropic / OpenAI-like)
# - AKIA + 16                           (AWS access key id)
# - bloc cle privee PEM
PATTERNS='ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{50,}|sk-ant-[A-Za-z0-9_-]{40,}|sk-[A-Za-z0-9]{40,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----'

# Ne scanne que les lignes AJOUTEES (un secret qu'on retire ne doit pas bloquer)
HITS=$(echo "$DIFF" | grep -E '^\+' | grep -onE "$PATTERNS" 2>/dev/null | head -3)

if [ -n "$HITS" ]; then
  {
    echo "✗ secret-scan : secret(s) à haute confiance détecté(s) dans le diff staged — commit bloqué."
    echo "  Type(s) repéré(s) : $(echo "$HITS" | sed -E 's/[A-Za-z0-9_-]{6,}/****/g' | sort -u | tr '\n' ' ')"
    echo "  Action : retirer du diff et déplacer en variable OMV \${VAR_NAME}, vérifier .gitignore."
    echo "  Audit complet : déléguer au subagent secret-scanner."
  } >&2
  exit 2
fi

exit 0
