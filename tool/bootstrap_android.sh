#!/usr/bin/env bash
set -euo pipefail

flutter create --platforms=android --org ir.tondro --project-name tondro .

# Remove Flutter template/demo files that are not part of Tondro.
rm -f test/widget_test.dart tondro.iml
rm -rf .idea

python3 - <<'PY'
from pathlib import Path

gradle = Path("android/app/build.gradle.kts")
if gradle.exists():
    text = gradle.read_text(encoding="utf-8")
    text = text.replace('applicationId = "ir.tondro.tondro"', 'applicationId = "ir.tondro.app"')
    gradle.write_text(text, encoding="utf-8")

manifest = Path("android/app/src/main/AndroidManifest.xml")
if manifest.exists():
    text = manifest.read_text(encoding="utf-8")
    permission = '<uses-permission android:name="android.permission.INTERNET"/>'
    if permission not in text:
        text = text.replace("<manifest", "<manifest", 1)
        first_close = text.find(">")
        text = text[:first_close+1] + "\n    " + permission + text[first_close+1:]
    text = text.replace('android:label="tondro"', 'android:label="تندرو"')
    manifest.write_text(text, encoding="utf-8")
PY

echo "Android platform prepared for Tondro."
