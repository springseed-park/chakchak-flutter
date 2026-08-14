#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
keystore_dir="$project_dir/android/keystore"
keystore_path="$keystore_dir/chakchak-upload.jks"

mkdir -p "$keystore_dir"
if [[ -e "$keystore_path" ]]; then
  echo "Upload keystore already exists: $keystore_path"
  exit 1
fi

keytool -genkeypair -v \
  -keystore "$keystore_path" \
  -alias upload \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000

echo "Created: $keystore_path"
echo "Next: copy android/key.properties.example to android/key.properties and enter the passwords."
