#!/bin/sh
set -e

HOME_DIR="${HOME:-/github/home}"
mkdir -p "$HOME_DIR/.config/godot"
mkdir -p /root/.config/godot

JAVA_BIN=$(which java 2>/dev/null || echo "/usr/bin/java")
JAVA_REAL=$(readlink -f "$JAVA_BIN" 2>/dev/null || echo "$JAVA_BIN")
JAVA_DIR=$(dirname $(dirname "$JAVA_REAL"))
ANDROID_DIR="${ANDROID_HOME:-/usr/lib/android-sdk}"
KEYSTORE="$HOME_DIR/debug.keystore"

# Ensure Android build-tools 34 compatibility for Godot 4.3
if [ -d "$ANDROID_DIR/build-tools/33.0.2" ] && [ ! -d "$ANDROID_DIR/build-tools/34.0.0" ]; then
  ln -s "$ANDROID_DIR/build-tools/33.0.2" "$ANDROID_DIR/build-tools/34.0.0" || true
fi
if [ -d "$ANDROID_DIR/platforms/android-33" ] && [ ! -d "$ANDROID_DIR/platforms/android-34" ]; then
  ln -s "$ANDROID_DIR/platforms/android-33" "$ANDROID_DIR/platforms/android-34" || true
fi

# Try sdkmanager if available
if which sdkmanager >/dev/null 2>&1; then
  yes | sdkmanager --licenses >/dev/null 2>&1 || true
  sdkmanager "build-tools;34.0.0" "platforms;android-34" >/dev/null 2>&1 || true
fi

# Copy keystore to HOME and root
cp debug.keystore "$HOME_DIR/debug.keystore" 2>/dev/null || true
cp debug.keystore /root/debug.keystore 2>/dev/null || true

echo "Configuring Godot CI:"
echo "  Java Home: $JAVA_DIR"
echo "  Android SDK: $ANDROID_DIR"
echo "  Keystore: $KEYSTORE"
echo "  Home dir: $HOME_DIR"

cat > "$HOME_DIR/.config/godot/editor_settings-4.tres" << EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$ANDROID_DIR"
export/android/java_sdk_path = "$JAVA_DIR"
export/android/debug_keystore = "$KEYSTORE"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
EOF

cp "$HOME_DIR/.config/godot/editor_settings-4.tres" /root/.config/godot/editor_settings-4.tres 2>/dev/null || true

# Copy templates to $HOME
mkdir -p "$HOME_DIR/.local/share/godot/export_templates/4.3.stable"
mkdir -p "$HOME_DIR/.local/share/godot/templates/4.3.stable"
mkdir -p /root/.local/share/godot/export_templates/4.3.stable

for d in /root/.local/share/godot/templates/4.3.stable /root/.local/share/godot/export_templates/4.3.stable /usr/local/share/godot/templates/4.3.stable; do
  if [ -d "$d" ]; then
    cp -rn "$d"/* "$HOME_DIR/.local/share/godot/export_templates/4.3.stable/" 2>/dev/null || true
    cp -rn "$d"/* "$HOME_DIR/.local/share/godot/templates/4.3.stable/" 2>/dev/null || true
    cp -rn "$d"/* /root/.local/share/godot/export_templates/4.3.stable/ 2>/dev/null || true
  fi
done

echo "Template contents in $HOME_DIR:"
ls -la "$HOME_DIR/.local/share/godot/export_templates/4.3.stable/" || true

echo "CI Environment Configured Successfully!"
