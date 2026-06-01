// common.js — utilitaires partagés entre les apps Pock

// Escape user-generated content before injecting into innerHTML
function esc(s) {
  const d = document.createElement('div');
  d.textContent = s == null ? '' : String(s);
  return d.innerHTML;
}

// Unique id: timestamp base36 + random suffix (no collision even in same ms)
function genId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
}

// Service worker registration with reload-loop guard
if ('serviceWorker' in navigator) {
  // hadController : skip the very first install (no prior controller) — sinon
  // clients.claim() au premier chargement émet controllerchange et déclenche
  // un reload en plein démarrage. updateViaCache:'none' : ne pas servir un
  // sw.js périmé depuis le cache HTTP (sinon le bump CACHE peut tarder).
  const hadController = !!navigator.serviceWorker.controller;
  navigator.serviceWorker.register('./sw.js', { updateViaCache: 'none' }).catch(() => {});
  let refreshing = false;
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (refreshing || !hadController) return;
    refreshing = true;
    window.location.reload();
  });
}

// ---------- Export / Import of all Pock data ----------

const POCK_PREFIX = 'pock-';

function pockListKeys() {
  const keys = [];
  for (let i = 0; i < localStorage.length; i++) {
    const k = localStorage.key(i);
    if (k && k.startsWith(POCK_PREFIX)) keys.push(k);
  }
  return keys;
}

function pockExportAll() {
  const data = {};
  pockListKeys().forEach(k => { data[k] = localStorage.getItem(k); });
  return { version: 1, exportedAt: new Date().toISOString(), data };
}

function pockExportToFile() {
  const exp = pockExportAll();
  const blob = new Blob([JSON.stringify(exp, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  const date = new Date().toISOString().split('T')[0];
  a.href = url;
  a.download = `pock-backup-${date}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

function pockImportFromJSON(json, mode) {
  mode = mode || 'merge'; // 'merge' | 'replace'
  let obj;
  try { obj = typeof json === 'string' ? JSON.parse(json) : json; }
  catch (_) { throw new Error('JSON invalide'); }
  if (!obj || typeof obj !== 'object' || !obj.data || typeof obj.data !== 'object') {
    throw new Error('Format invalide — ce fichier ne ressemble pas à un export Pock');
  }
  if (mode === 'replace') {
    pockListKeys().forEach(k => localStorage.removeItem(k));
  }
  let count = 0;
  Object.entries(obj.data).forEach(([k, v]) => {
    if (typeof k === 'string' && k.startsWith(POCK_PREFIX) && typeof v === 'string') {
      localStorage.setItem(k, v);
      count++;
    }
  });
  return count;
}
