#!/usr/bin/env python3
"""Regression test for commit-specific Godot Web filenames."""

from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from version_web_export import RUNTIME_FILES, version_web_export


class VersionWebExportTest(unittest.TestCase):
    def test_versions_every_runtime_file_and_html_reference(self) -> None:
        build_id = "0123456789abcdef0123456789abcdef01234567"
        with tempfile.TemporaryDirectory() as temp_dir:
            build_dir = Path(temp_dir)
            html = """\
<!doctype html>
<html>
<head>
<link rel="icon" href="index.icon.png">
<link rel="apple-touch-icon" href="index.apple-touch-icon.png">
</head>
<body>
<img src="index.png">
<script src="index.js"></script>
<script>
const GODOT_CONFIG = {"executable":"index","fileSizes":{"index.pck":1,"index.wasm":2}};
</script>
</body>
</html>
"""
            (build_dir / "index.html").write_text(html, encoding="utf-8")
            for name in RUNTIME_FILES:
                (build_dir / name).write_bytes(name.encode("utf-8"))

            version_web_export(build_dir, build_id)

            versioned_prefix = f"index-{build_id}"
            rewritten = (build_dir / "index.html").read_text(encoding="utf-8")
            self.assertIn(
                f'<meta name="vampiros-build" content="{build_id}">',
                rewritten,
            )
            self.assertIn(f'"executable":"{versioned_prefix}"', rewritten)
            for source_name in RUNTIME_FILES:
                target_name = source_name.replace("index", versioned_prefix, 1)
                self.assertFalse((build_dir / source_name).exists())
                self.assertTrue((build_dir / target_name).is_file())
                if source_name not in (
                    "index.audio.position.worklet.js",
                    "index.audio.worklet.js",
                ):
                    self.assertIn(target_name, rewritten)


if __name__ == "__main__":
    unittest.main()
