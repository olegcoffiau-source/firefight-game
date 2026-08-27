import os
import subprocess
import glob

def find_path(cmd):
    try:
        out = subprocess.check_output(["which", cmd], stderr=subprocess.DEVNULL).decode().strip()
        real = os.path.realpath(out)
        return os.path.dirname(os.path.dirname(real))
    except Exception:
        return None

# 1. Find Java
java_dir = find_path("javac") or find_path("java") or "/usr/lib/jvm/java-17-openjdk-amd64"

# 2. Find Android SDK
android_dir = None
for candidate in [os.environ.get("ANDROID_HOME"), os.environ.get("ANDROID_SDK_ROOT"), "/usr/lib/android-sdk", "/usr/lib/android/sdk", "/opt/android-sdk"]:
    if candidate and os.path.exists(candidate):
        android_dir = candidate
        break

if not android_dir:
    apksigners = glob.glob("/usr/**/apksigner", recursive=True) + glob.glob("/opt/**/apksigner", recursive=True)
    if apksigners:
        android_dir = apksigners[0].split("/build-tools/")[0]
    else:
        android_dir = "/usr/lib/android-sdk"

workspace = os.environ.get("GITHUB_WORKSPACE", os.getcwd())
keystore = os.path.join(workspace, "debug.keystore")
home_dir = os.environ.get("HOME", "/github/home")

print(f"Detected Java Home: {java_dir}")
print(f"Detected Android SDK: {android_dir}")
print(f"Debug Keystore: {keystore}")

settings_content = f"""[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "{android_dir}"
export/android/java_sdk_path = "{java_dir}"
export/android/debug_keystore = "{keystore}"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
"""

for target in [f"{home_dir}/.config/godot", "/root/.config/godot", os.path.expanduser("~/.config/godot")]:
    os.makedirs(target, exist_ok=True)
    settings_file = os.path.join(target, "editor_settings-4.tres")
    with open(settings_file, "w", encoding="utf-8") as f:
        f.write(settings_content)
    print(f"Wrote settings to: {settings_file}")

# Also copy templates
for d in ["/root/.local/share/godot/templates/4.3.stable", "/root/.local/share/godot/export_templates/4.3.stable", "/usr/local/share/godot/templates/4.3.stable"]:
    if os.path.exists(d):
        for dest in [f"{home_dir}/.local/share/godot/export_templates/4.3.stable", f"{home_dir}/.local/share/godot/templates/4.3.stable", "/root/.local/share/godot/export_templates/4.3.stable"]:
            os.makedirs(dest, exist_ok=True)
            subprocess.run(f"cp -rn {d}/* {dest}/ 2>/dev/null || true", shell=True)
            print(f"Copied templates from {d} to {dest}")

print("Godot 4 Android CI Environment Successfully Configured!")
