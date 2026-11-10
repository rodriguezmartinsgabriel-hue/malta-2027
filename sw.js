/* Malta 2027 - Service Worker (Workbox)
   Estrategias:
   - App shell (html/manifest/icones): StaleWhileRevalidate
   - MapLibre + OpenFreeMap tiles: CacheFirst (offline map tiles after first view)
   - Open-Meteo / Frankfurter / Nominatim: NetworkFirst com fallback cache
   - Google Fonts: StaleWhileRevalidate
*/
importScripts('https://storage.googleapis.com/workbox-cdn/releases/7.1.0/workbox-sw.js');

if (workbox) {
  workbox.core.setCacheNameDetails({ prefix: 'malta2027', suffix: 'v3' });
  workbox.core.clientsClaim();
  self.skipWaiting();

  // App shell
  workbox.precaching.precacheAndRoute([
    { url: './', revision: 'v3' },
    { url: './index.html', revision: 'v3' },
    { url: './manifest.webmanifest', revision: 'v3' },
    { url: './icon-192.png', revision: 'v3' },
    { url: './icon-512.png', revision: 'v3' },
    { url: './apple-touch-icon.png', revision: 'v3' }
  ], { ignoreURLParametersMatching: [/.*/] });

  // Navigation: network first, fall back to cached shell
  workbox.routing.registerRoute(
    ({ request }) => request.mode === 'navigate',
    new workbox.strategies.NetworkFirst({
      cacheName: 'malta2027-pages',
      networkTimeoutSeconds: 4
    })
  );

  // MapLibre + tiles (OpenFreeMap) - cache first so the map works offline after first load
  workbox.routing.registerRoute(
    ({ url }) => url.hostname.includes('maplibre') || url.hostname.includes('openfreemap') || url.hostname.includes('unpkg.com'),
    new workbox.strategies.CacheFirst({
      cacheName: 'malta2027-map',
      plugins: [
        new workbox.expiration.ExpirationPlugin({ maxEntries: 400, maxAgeSeconds: 60 * 60 * 24 * 30 })
      ]
    })
  );

  // Weather + FX + places - network first (fresh data), fall back to cache
  workbox.routing.registerRoute(
    ({ url }) => url.hostname.includes('open-meteo') || url.hostname.includes('frankfurter') || url.hostname.includes('er-api') || url.hostname.includes('nominatim'),
    new workbox.strategies.NetworkFirst({
      cacheName: 'malta2027-data',
      networkTimeoutSeconds: 5,
      plugins: [
        new workbox.expiration.ExpirationPlugin({ maxEntries: 40, maxAgeSeconds: 60 * 60 * 24 })
      ]
    })
  );

  // Fonts
  workbox.routing.registerRoute(
    ({ url }) => url.hostname.includes('fonts.g') || url.hostname.includes('gstatic'),
    new workbox.strategies.StaleWhileRevalidate({
      cacheName: 'malta2027-fonts',
      plugins: [
        new workbox.expiration.ExpirationPlugin({ maxEntries: 20, maxAgeSeconds: 60 * 60 * 24 * 365 })
      ]
    })
  );
} else {
  // Fallback simples se o CDN do Workbox falhar
  const CACHE = 'malta2027-v3-fallback';
  self.addEventListener('install', e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(['./','./index.html','./manifest.webmanifest']))); self.skipWaiting(); });
  self.addEventListener('activate', e => { e.waitUntil(self.clients.claim()); });
  self.addEventListener('fetch', e => { e.respondWith(caches.match(e.request).then(r => r || fetch(e.request))); });
}
