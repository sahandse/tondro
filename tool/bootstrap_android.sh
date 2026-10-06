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

    text = text.replace(
        '<application',
        '<application android:icon="@drawable/ic_tondro" android:roundIcon="@drawable/ic_tondro"',
        1,
    )
    manifest.write_text(text, encoding="utf-8")

icon = Path("android/app/src/main/res/drawable/ic_tondro.xml")
icon.parent.mkdir(parents=True, exist_ok=True)
icon.write_text("""<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#000000" android:pathData="M0,0h108v108h-108z"/>
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M49,18h10v43h13L54,81L36,61h13z"/>
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M28,86h52v7h-52z"/>
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M68,18L57,39h10L57,56l23,-28h-11l9,-10z"/>
</vector>
""", encoding="utf-8")

launch = Path("android/app/src/main/res/drawable/launch_background.xml")
if launch.exists():
    launch.write_text("""<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="#000000" />
    <item
        android:width="96dp"
        android:height="96dp"
        android:gravity="center"
        android:drawable="@drawable/ic_tondro" />
</layer-list>
""", encoding="utf-8")
PY

# Patch receive_sharing_intent 1.8.1 JVM target to match Flutter/JDK 17.
PLUGIN_GRADLE="$HOME/.pub-cache/hosted/pub.dev/receive_sharing_intent-1.8.1/android/build.gradle"
if [ -f "$PLUGIN_GRADLE" ]; then
  python3 - "$PLUGIN_GRADLE" <<'PYPLUGIN'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

if "sourceCompatibility JavaVersion.VERSION_17" not in text:
    android_marker = "android {"
    insertion = """android {
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = '17'
    }
"""
    text = text.replace(android_marker, insertion, 1)

text = text.replace("JavaVersion.VERSION_11", "JavaVersion.VERSION_17")
text = text.replace("JavaVersion.VERSION_1_8", "JavaVersion.VERSION_17")
text = text.replace("jvmTarget = '11'", "jvmTarget = '17'")
text = text.replace('jvmTarget = "11"', 'jvmTarget = "17"')
text = text.replace("jvmTarget = '1.8'", "jvmTarget = '17'")
text = text.replace('jvmTarget = "1.8"', 'jvmTarget = "17"')

path.write_text(text, encoding="utf-8")
PYPLUGIN
fi

echo "Android platform prepared for Tondro."
