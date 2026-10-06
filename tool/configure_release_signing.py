from pathlib import Path

gradle = Path("android/app/build.gradle.kts")
if not gradle.exists():
    raise SystemExit("android/app/build.gradle.kts not found")

text = gradle.read_text(encoding="utf-8")

signing_block = """
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("ANDROID_KEYSTORE_PATH"))
            storePassword = System.getenv("ANDROID_STORE_PASSWORD")
            keyAlias = System.getenv("ANDROID_KEY_ALIAS")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
        }
    }

"""

if 'create("release")' not in text:
    marker = "    buildTypes {"
    if marker not in text:
        raise SystemExit("buildTypes block not found")
    text = text.replace(marker, signing_block + marker, 1)

text = text.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")',
)

gradle.write_text(text, encoding="utf-8")
print("Release signing configured.")
