/* SCL fallback service worker — v99.
   Only include this file if your GitHub repo does not already have its own sw.js.
   If you already have one, keep yours; do not overwrite it with this unless you
   understand what your existing one does (this one is intentionally minimal). */
const CACHE_NAME = 'scl-shell-v99';
const SHELL_FILES = ['./index.html', './manifest.webmanifest'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(SHELL_FILES)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

/* Network-first for everything so authenticated/dynamic content (auth, payments,
   attendance, results) never gets served stale from cache. Falls back to the
   cached app shell only when fully offline. This deliberately avoids caching
   API/edge-function responses to prevent stale payment or attendance state. */
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy)).catch(() => {});
        return response;
      })
      .catch(() => caches.match(event.request).then((cached) => cached || caches.match('./index.html')))
  );
});
