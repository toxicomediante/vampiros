"use strict";

// Godot's former PWA export registered this exact worker URL. Serving this
// one-shot replacement lets existing browser profiles retire the stale worker
// and its VAMPIROS-only Cache Storage entries without touching saves/settings.

async function deleteScopedCacheEntries() {
	const scope = new URL(self.registration.scope);
	for (const cacheName of await caches.keys()) {
		const cache = await caches.open(cacheName);
		for (const request of await cache.keys()) {
			const url = new URL(request.url);
			if (url.origin === scope.origin && url.pathname.startsWith(scope.pathname)) {
				await cache.delete(request);
			}
		}
		if ((await cache.keys()).length === 0) await caches.delete(cacheName);
	}
}

self.addEventListener("install", (event) => {
	event.waitUntil(self.skipWaiting());
});

self.addEventListener("activate", (event) => {
	event.waitUntil((async () => {
		await deleteScopedCacheEntries();
		const windows = await self.clients.matchAll({
			type: "window",
			includeUncontrolled: true,
		});
		await self.registration.unregister();
		await Promise.all(windows.map((client) => client.navigate(client.url)));
	})());
});
