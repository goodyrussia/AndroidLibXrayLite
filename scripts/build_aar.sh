#!/usr/bin/env bash
# Build libv2ray.aar (arm64-v8a) = AndroidLibXrayLite wrapper + Xray-core v1.260123.0-patch.1 (eichgee),
# packaged with the upstream JNI+CLI-shared pipeline (libxray.so launcher REQUIRED by root-mode clients).
# Requires: Go 1.25+, ANDROID_NDK_HOME (r26+), ANDROID_HOME with platforms/ + build-tools/.
set -euo pipefail

CORE_REPO=https://github.com/eichgee/Xray-core
CORE_TAG=v1.260123.0-patch.1
# go1.24-era x/mobile: newer x/mobile/x/text force `go 1.26` which trips a gvisor
# dual-file build-tag collision with this core's gvisor pin.
XMOBILE=v0.0.0-20251126181937-5c265dc024c4
WORK=${WORK:-$(pwd)/.core-build}
HERE=$(cd "$(dirname "$0")/.." && pwd)

: "${ANDROID_NDK_HOME:?set ANDROID_NDK_HOME to your NDK}"
: "${ANDROID_HOME:?set ANDROID_HOME to your SDK (needs platforms/ and build-tools/)}"

git clone --depth 1 --branch "$CORE_TAG" "$CORE_REPO" "$WORK" 2>/dev/null || {
  git -C "$WORK" fetch --depth 1 --tags "$CORE_REPO" "$CORE_TAG"
  git -C "$WORK" checkout -f "$CORE_TAG"
}

# Wrapper becomes a libv2ray/ package inside the core module (core's own dep set — no drift),
# plus the upstream JNI+CLI packaging script and launcher.
mkdir -p "$WORK/libv2ray" "$WORK/scripts" "$WORK/native/cli"
cp "$HERE"/libv2ray_*.go "$WORK/libv2ray/"
cp "$HERE"/scripts/build_shared.py "$WORK/scripts/"
cp "$HERE"/native/cli/launcher.c "$HERE"/native/cli/export.go.txt "$WORK/native/cli/"
# build_shared.py binds the repo root ('.'); our wrapper package lives in libv2ray/.
sed -i "s|'-o', baseline, '.'\]|'-o', baseline, './libv2ray']|" "$WORK/scripts/build_shared.py"

cd "$WORK"
go get -tool golang.org/x/mobile/cmd/gomobile@"$XMOBILE"
go install golang.org/x/mobile/cmd/gomobile@"$XMOBILE" golang.org/x/mobile/cmd/gobind@"$XMOBILE"
go build ./libv2ray/

python3 scripts/build_shared.py --arch arm64 --output "$HERE/libv2ray.aar" --work-dir "$WORK/shared-work"

# Bundle geodata as AAR assets (mirrors upstream AndroidLibXrayLite layout).
(cd "$HERE" && zip -q libv2ray.aar assets/geoip.dat assets/geosite.dat assets/geoip-only-cn-private.dat)
echo "Built $HERE/libv2ray.aar"
