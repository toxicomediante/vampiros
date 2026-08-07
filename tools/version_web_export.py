#!/usr/bin/env python3
"""Give every Godot Web payload a commit-specific URL.

GitHub Pages and browsers may keep large Web exports in cache. Godot normally
reuses names such as ``index.pck`` and ``index.wasm`` for every deployment, so
an old file can be paired with a newer export. This post-processing step keeps
``index.html`` as the public entry point while renaming every runtime payload
with the build commit and updating Godot's generated HTML accordingly.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re


BUILD_ID_PATTERN = re.compile(r"[0-9a-f]{7,40}")
RUNTIME_FILES = (
    "index.js",
    "index.pck",
    "index.wasm",
    "index.audio.position.worklet.js",
    "index.audio.worklet.js",
    "index.apple-touch-icon.png",
    "index.icon.png",
    "index.png",
)
CACHE_META = """\
		<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
		<meta http-equiv="Pragma" content="no-cache">
		<meta http-equiv="Expires" content="0">
"""


def legacy_service_worker_cleanup(build_id: str) -> str:
    """Return a one-shot cleanup for the PWA worker used by older exports.

    VAMPIROS briefly shipped with Godot's PWA export enabled. Disabling the
    option stops creating a worker, but it does not remove a worker already
    installed in a browser profile. That stale worker can keep serving an old
    HTML/runtime combination indefinitely. Only Cache Storage entries inside
    this deployment path are removed; game saves and settings are untouched.
    """
    return f"""\
		<script>
		(() => {{
			"use strict";
			const buildId = "{build_id}";
			const cleanupKey = `vampiros-sw-cleanup-${{buildId}}`;
			const appRoot = new URL("./", window.location.href);

			async function deleteScopedCacheEntries() {{
				if (!("caches" in window)) return false;
				let changed = false;
				for (const cacheName of await caches.keys()) {{
					const cache = await caches.open(cacheName);
					for (const request of await cache.keys()) {{
						const url = new URL(request.url);
						if (url.origin === appRoot.origin && url.pathname.startsWith(appRoot.pathname)) {{
							changed = (await cache.delete(request)) || changed;
						}}
					}}
					if ((await cache.keys()).length === 0) await caches.delete(cacheName);
				}}
				return changed;
			}}

			async function removeLegacyWorker() {{
				if (!("serviceWorker" in navigator)) return false;
				let changed = false;
				for (const registration of await navigator.serviceWorker.getRegistrations()) {{
					if (registration.scope === appRoot.href) {{
						changed = (await registration.unregister()) || changed;
					}}
				}}
				return changed;
			}}

			if (sessionStorage.getItem(cleanupKey) === "done") return;
			Promise.all([removeLegacyWorker(), deleteScopedCacheEntries()])
				.then(([workerRemoved, cacheChanged]) => {{
					sessionStorage.setItem(cleanupKey, "done");
					if (!workerRemoved && !cacheChanged) return;
					const refreshed = new URL(window.location.href);
					refreshed.searchParams.set("v", buildId.slice(0, 12));
					window.location.replace(refreshed.href);
				}})
				.catch((error) => console.warn("VAMPIROS cache cleanup failed", error));
		}})();
		</script>
"""


def version_web_export(build_dir: Path, build_id: str) -> None:
    """Rename generated runtime files and rewrite their HTML references."""
    if BUILD_ID_PATTERN.fullmatch(build_id) is None:
        raise ValueError("build id must be a 7-40 character lowercase Git SHA")

    index_path = build_dir / "index.html"
    if not index_path.is_file():
        raise ValueError(f"missing Godot Web entry point: {index_path}")

    missing = [name for name in RUNTIME_FILES if not (build_dir / name).is_file()]
    if missing:
        raise ValueError("missing Godot Web runtime files: " + ", ".join(missing))

    versioned_prefix = f"index-{build_id}"
    html = index_path.read_text(encoding="utf-8")

    executable_token = '"executable":"index"'
    if html.count(executable_token) != 1:
        raise ValueError("could not find exactly one Godot executable setting")
    html = html.replace(
        executable_token,
        f'"executable":"{versioned_prefix}"',
    )

    for source_name in RUNTIME_FILES:
        target_name = source_name.replace("index", versioned_prefix, 1)
        html = html.replace(source_name, target_name)
        (build_dir / source_name).rename(build_dir / target_name)

    head_token = "<head>"
    if html.count(head_token) != 1:
        raise ValueError("could not find exactly one HTML head")
    html = html.replace(
        head_token,
        f'{head_token}\n\t\t<meta name="vampiros-build" content="{build_id}">\n'
        f"{CACHE_META}{legacy_service_worker_cleanup(build_id)}",
        1,
    )
    index_path.write_text(html, encoding="utf-8")

    stale = [name for name in RUNTIME_FILES if (build_dir / name).exists()]
    if stale:
        raise ValueError("unversioned runtime files remain: " + ", ".join(stale))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("build_dir", type=Path)
    parser.add_argument("build_id")
    args = parser.parse_args()

    try:
        version_web_export(args.build_dir, args.build_id)
    except (OSError, ValueError) as exc:
        raise SystemExit(f"WEB VERSIONING FAILED: {exc}") from exc

    print(f"WEB VERSIONED: {args.build_id}")


if __name__ == "__main__":
    main()
