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
    text = text.replace(
        "compileOptions {\n        sourceCompatibility = JavaVersion.VERSION_11\n        targetCompatibility = JavaVersion.VERSION_11\n    }",
        "compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n        sourceCompatibility = JavaVersion.VERSION_17\n        targetCompatibility = JavaVersion.VERSION_17\n    }",
    )
    marker = "dependencies {"
    if marker in text and "desugar_jdk_libs" not in text:
        text = text.replace(
            marker,
            marker + '\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")'
        )
    elif marker not in text and "desugar_jdk_libs" not in text:
        text += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")\n}\n'
    gradle.write_text(text, encoding="utf-8")

root_gradle = Path("android/build.gradle.kts")
if root_gradle.exists():
    text = root_gradle.read_text(encoding="utf-8")
    compatibility = """

subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
}
"""
    if "tasks.withType<JavaCompile>()" not in text:
        text += compatibility
    root_gradle.write_text(text, encoding="utf-8")

manifest = Path("android/app/src/main/AndroidManifest.xml")
if manifest.exists():
    text = manifest.read_text(encoding="utf-8")
    permissions = [
        '<uses-permission android:name="android.permission.INTERNET"/>',
        '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
    ]
    first_close = text.find(">")
    for permission in permissions:
        if permission not in text:
            text = text[:first_close+1] + "\n    " + permission + text[first_close+1:]
            first_close = text.find(">")

    text = text.replace('android:label="tondro"', 'android:label="تندرو"')
    if 'android:launchMode="singleTop"' in text:
        text = text.replace(
            'android:launchMode="singleTop"',
            'android:launchMode="singleTask"',
        )
    elif 'android:launchMode=' not in text:
        text = text.replace(
            'android:name=".MainActivity"',
            'android:name=".MainActivity"\n            android:launchMode="singleTask"',
        )

    share_filter = '''\n            <intent-filter>\n                <action android:name="android.intent.action.SEND" />\n                <category android:name="android.intent.category.DEFAULT" />\n                <data android:mimeType="text/*" />\n            </intent-filter>\n'''
    if 'android.intent.action.SEND' not in text:
        marker = '</activity>'
        text = text.replace(marker, share_filter + '        ' + marker, 1)

    manifest.write_text(text, encoding="utf-8")
PY

echo "Android platform prepared for Tondro."
