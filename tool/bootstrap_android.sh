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

    widget_launch_filter = '''\n            <intent-filter>\n                <action android:name="es.antonborri.home_widget.action.LAUNCH" />\n                <category android:name="android.intent.category.DEFAULT" />\n            </intent-filter>\n'''
    if 'es.antonborri.home_widget.action.LAUNCH' not in text:
        marker = '</activity>'
        text = text.replace(marker, widget_launch_filter + '        ' + marker, 1)

    widget_receiver = '''\n        <receiver\n            android:name="ir.tondro.tondro.TondroWidgetProvider"\n            android:exported="true">\n            <intent-filter>\n                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />\n            </intent-filter>\n            <meta-data\n                android:name="android.appwidget.provider"\n                android:resource="@xml/tondro_widget_info" />\n        </receiver>\n'''
    if 'TondroWidgetProvider' not in text:
        text = text.replace('</application>', widget_receiver + '    </application>', 1)

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
    <path android:fillColor="#08152E" android:pathData="M0,0h108v108h-108z"/>
    <path
        android:fillColor="#54E6FF"
        android:pathData="M54,9C35,20 31,35 44,45C57,55 72,53 78,42C82,34 73,27 54,9Z"/>
    <path
        android:fillColor="#177FFF"
        android:pathData="M35,38C42,50 67,51 72,63C76,72 66,80 55,81C64,70 55,62 40,56C27,51 26,44 35,38Z"/>
    <path
        android:fillColor="#1553E8"
        android:pathData="M23,65L46,69L46,59L54,81L85,66L73,89C60,101 45,100 32,88Z"/>
    <path
        android:fillColor="#79F2FF"
        android:pathData="M54,9C46,15 40,20 36,26C43,19 50,16 58,14Z"/>
    <path
        android:fillColor="#54E6FF"
        android:pathData="M23,65L46,69L43,74L29,72Z"/>
</vector>
""", encoding="utf-8")

launch = Path("android/app/src/main/res/drawable/launch_background.xml")
if launch.exists():
    launch.write_text("""<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="#08152E" />
    <item
        android:width="96dp"
        android:height="96dp"
        android:gravity="center"
        android:drawable="@drawable/ic_tondro" />
</layer-list>
""", encoding="utf-8")

widget_bg = Path("android/app/src/main/res/drawable/tondro_widget_bg.xml")
widget_bg.write_text("""<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#111111" />
    <corners android:radius="18dp" />
    <stroke android:width="1dp" android:color="#333333" />
    <padding android:left="14dp" android:top="12dp" android:right="14dp" android:bottom="12dp" />
</shape>
""", encoding="utf-8")

layout = Path("android/app/src/main/res/layout/tondro_widget.xml")
layout.parent.mkdir(parents=True, exist_ok=True)
layout.write_text("""<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@drawable/tondro_widget_bg"
    android:padding="12dp">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:gravity="center_vertical"
        android:orientation="horizontal">

        <TextView
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="تندرو"
            android:textColor="#FFFFFF"
            android:textSize="16sp"
            android:textStyle="bold" />

        <TextView
            android:id="@+id/widget_speed"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="0 KB/s"
            android:textColor="#68B5FF"
            android:textSize="13sp"
            android:textStyle="bold" />
    </LinearLayout>

    <TextView
        android:id="@+id/widget_file"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:ellipsize="middle"
        android:maxLines="1"
        android:text="دانلود فعالی نیست"
        android:textColor="#EDEDED"
        android:textDirection="ltr"
        android:textSize="13sp" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="10dp"
        android:gravity="center_vertical"
        android:orientation="horizontal">

        <TextView
            android:id="@+id/widget_count"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="0 دانلود فعال"
            android:textColor="#AAAAAA"
            android:textSize="12sp" />

        <Button
            android:id="@+id/widget_pause"
            android:layout_width="52dp"
            android:layout_height="40dp"
            android:text="Ⅱ"
            android:textSize="14sp" />

        <Button
            android:id="@+id/widget_resume"
            android:layout_width="52dp"
            android:layout_height="40dp"
            android:layout_marginLeft="6dp"
            android:text="▶"
            android:textSize="14sp" />
    </LinearLayout>
</LinearLayout>
""", encoding="utf-8")

widget_info = Path("android/app/src/main/res/xml/tondro_widget_info.xml")
widget_info.parent.mkdir(parents=True, exist_ok=True)
widget_info.write_text("""<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:initialLayout="@layout/tondro_widget"
    android:minWidth="250dp"
    android:minHeight="110dp"
    android:minResizeWidth="180dp"
    android:minResizeHeight="90dp"
    android:resizeMode="horizontal|vertical"
    android:updatePeriodMillis="0"
    android:widgetCategory="home_screen" />
""", encoding="utf-8")

provider = Path("android/app/src/main/kotlin/ir/tondro/tondro/TondroWidgetProvider.kt")
provider.parent.mkdir(parents=True, exist_ok=True)
provider.write_text("""package ir.tondro.tondro

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class TondroWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val activeCount = widgetData.getInt("active_count", 0)
            val fileName = widgetData.getString("current_file", "دانلود فعالی نیست")
                ?: "دانلود فعالی نیست"
            val speed = widgetData.getString("speed_text", "0 KB/s") ?: "0 KB/s"

            val views = RemoteViews(context.packageName, R.layout.tondro_widget).apply {
                setTextViewText(R.id.widget_count, "$activeCount دانلود فعال")
                setTextViewText(R.id.widget_file, fileName)
                setTextViewText(R.id.widget_speed, speed)

                val pauseIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("tondro://pause")
                )
                val resumeIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("tondro://resume")
                )
                setOnClickPendingIntent(R.id.widget_pause, pauseIntent)
                setOnClickPendingIntent(R.id.widget_resume, resumeIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
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
