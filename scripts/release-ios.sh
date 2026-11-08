#!/bin/bash
# Called after installing the distribution certificate and provisioning profile.
set -euo pipefail
cd "$(dirname "$0")/.."

for name in APPLE_TEAM_ID ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_PATH IOS_PROFILE_NAME BUILD_NUMBER; do
    if [[ -z "${!name:-}" ]]; then
        echo "Missing required setting: $name" >&2
        exit 2
    fi
done
[[ -f "$ASC_KEY_PATH" ]] || { echo 'API key file is missing.' >&2; exit 2; }
[[ "$BUILD_NUMBER" =~ ^[1-9][0-9]{0,3}\.[1-9][0-9]?$ ]] || { echo 'BUILD_NUMBER must be run.attempt (1–9999 and 1–99).' >&2; exit 2; }

release_dir="$PWD/Build/AppStore"
mkdir -p "$release_dir"
export RELEASE_EXPORT_PLIST="$release_dir/ExportOptions.plist"
python3 - <<'PY'
import os
import plistlib

options = {
    'method': 'app-store-connect',
    'destination': 'upload',
    'teamID': os.environ['APPLE_TEAM_ID'],
    'signingStyle': 'manual',
    'signingCertificate': 'Apple Distribution',
    'provisioningProfiles': {
        'de.aleksandr.DeutscheVerben': os.environ['IOS_PROFILE_NAME'],
    },
    'manageAppVersionAndBuildNumber': False,
    'uploadSymbols': True,
}
with open(os.environ['RELEASE_EXPORT_PLIST'], 'wb') as output:
    plistlib.dump(options, output)
PY

xcodebuild \
    "-IDECustomCompilationCacheLocation=$release_dir/CompilationCache" \
    -project DeutscheVerben.xcodeproj \
    -scheme DeutscheVerben \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$release_dir/DerivedData" \
    -archivePath "$release_dir/DeutscheVerben.xcarchive" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY='Apple Distribution' \
    PROVISIONING_PROFILE_SPECIFIER="$IOS_PROFILE_NAME" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    CLANG_ENABLE_COMPILE_CACHE=NO \
    SWIFT_ENABLE_COMPILE_CACHE=NO \
    archive

xcodebuild -exportArchive \
    -archivePath "$release_dir/DeutscheVerben.xcarchive" \
    -exportOptionsPlist "$RELEASE_EXPORT_PLIST" \
    -exportPath "$release_dir/Export" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$ASC_KEY_PATH" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"

echo 'Upload completed. Apple must process the build before it appears in TestFlight.'
