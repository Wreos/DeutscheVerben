#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."

platform=${1:-macOS}
action=${2:-build}
configuration=${CONFIGURATION:-Debug}
extra=()
if (( $# > 2 )); then
    extra=("${@:3}")
fi

case "$platform" in
    macOS) destination='platform=macOS' ;;
    iOS) destination='generic/platform=iOS Simulator' ;;
    *) print -u2 'Usage: scripts/build.sh [macOS|iOS] [build|test] [xcodebuild options]'; exit 2 ;;
esac
case "$action" in
    build|test) ;;
    *) print -u2 'Supported actions: build, test'; exit 2 ;;
esac
if [[ "$action" == test && "$platform" == iOS ]]; then
    : "${DESTINATION:?Set DESTINATION to an available iPhone Simulator destination}"
fi
destination=${DESTINATION:-$destination}
root="$PWD/Build/$platform"

xcodebuild \
    "-IDECustomCompilationCacheLocation=$root/CompilationCache" \
    -project DeutscheVerben.xcodeproj \
    -scheme DeutscheVerben \
    -configuration "$configuration" \
    -destination "$destination" \
    -derivedDataPath "$root/DerivedData" \
    OBJROOT="$root/Intermediates" \
    SYMROOT="$root/Products" \
    COMPILATION_CACHE_CAS_PATH="$root/CompilationCache" \
    CLANG_ENABLE_COMPILE_CACHE=NO \
    SWIFT_ENABLE_COMPILE_CACHE=NO \
    CODE_SIGNING_ALLOWED=YES \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_REQUIRED=NO \
    DEVELOPMENT_TEAM= \
    "$action" "${extra[@]}"
