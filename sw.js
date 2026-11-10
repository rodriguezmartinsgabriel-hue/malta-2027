/* Malta 2027 - service worker (sem dependencias externas).
   - Navegacao e arquivos do app: rede primeiro, cache como reserva (offline).
   - Fontes, MapLibre e tiles do mapa: cache primeiro.
   - APIs (clima, cotacao, busca) e Supabase: direto na rede, o app guarda o que precisa. */
const VERSION = 'v4';
const SHELL = 'malta2027-shell-' + VERSION;
const ASSETS = 'malta2027-assets-' + VERSION;
const SHELL_FILES = ['./', './manifest.webmanifest', './icon-192.png', './icon-512.png', './apple-touch-icon.png'];
const ASSET_HOSTS = ['fonts.googleapis.com', 'fonts.gstatic.com', 'unpkg.com', 'cdn.jsdelivr.net', 'tiles.openfreemap.org'];
const ASSET_LIMIT = 500;

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(SHELL)
      .then(cache => cache.addAll(SHELL_FILES.map(u => new Request(u, { cache: 'reload' }))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== SHELL && k !== ASSETS).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

async function networkFirst(request, fallbackUrl) {
  const cache = await caches.open(SHELL);
  try {
    const fresh = await fetch(request);
    if (fresh && fresh.ok) cache.put(fallbackUrl || request, fresh.clone());
    return fresh;
  } catch (err) {
    const hit = await cache.match(fallbackUrl || request, { ignoreSearch: true });
    if (hit) return hit;
    throw err;
  }
}

async function trim(cache) {
  const keys = await cache.keys();
  for (let i = 0; i < keys.length - ASSET_LIMIT; i++) await cache.delete(keys[i]);
}

async function cacheFirst(request) {
  const cache = await caches.open(ASSETS);
  const hit = await cache.match(request);
  if (hit) return hit;
  const fresh = await fetch(request);
  if (fresh && (fresh.ok || fresh.type === 'opaque')) {
    cache.put(request, fresh.clone()).then(() => trim(cache)).catch(() => {});
  }
  return fresh;
}

self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (request.mode === 'navigate' && url.origin === self.location.origin) {
    event.respondWith(networkFirst(request, './'));
    return;
  }
  if (url.origin === self.location.origin) {
    event.respondWith(networkFirst(request));
    return;
  }
  if (ASSET_HOSTS.indexOf(url.hostname) > -1) {
    event.respondWith(cacheFirst(request));
  }
});
