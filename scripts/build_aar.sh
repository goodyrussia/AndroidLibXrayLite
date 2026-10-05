#!/usr/bin/env bash
# Build libv2ray.aar (arm64-v8a) = AndroidLibXrayLite wrapper + Xray-core v1.260123.0-patch.1 (eichgee).
# Requires: Go 1.25+, ANDROID_NDK_HOME (r26+), ANDROID_HOME with platforms/ + build-tools/.
set -euo pipefail

CORE_REPO=https://github.com/eichgee/Xray-core
CORE_TAG=v1.260123.0-patch.1
# go1.24-era x/mobile: newer x/mobile/x/text force `go 1.26` which flips gvisor's
# dual runtime_constants files into a redeclaration collision. Pin stays.
XMOBILE=v0.0.0-20251126181937-5c265dc024c4
WORK=${WORK:-$(pwd)/.core-build}
HERE=$(cd "$(dirname "$0")/.." && pwd)

: "${ANDROID_NDK_HOME:?set ANDROID_NDK_HOME to your NDK}"
: "${ANDROID_HOME:?set ANDROID_HOME to your SDK (needs platforms/ and build-tools/)}"

git clone --depth 1 --branch "$CORE_TAG" "$CORE_REPO" "$WORK" 2>/dev/null || {
  git -C "$WORK" fetch --depth 1 --tags "$CORE_REPO" "$CORE_TAG"
  git -C "$WORK" checkout -f "$CORE_TAG"
}

mkdir -p "$WORK/libv2ray"
cp "$HERE"/libv2ray_*.go "$WORK/libv2ray/"

cd "$WORK"
go get -tool golang.org/x/mobile/cmd/gomobile@"$XMOBILE"
go install golang.org/x/mobile/cmd/gomobile@"$XMOBILE" golang.org/x/mobile/cmd/gobind@"$XMOBILE"
go build ./libv2ray/

gomobile bind -target=android/arm64 -androidapi 24 -o "$HERE/libv2ray.aar" github.com/xtls/xray-core/libv2ray

# Bundle geodata as AAR assets (mirrors upstream AndroidLibXrayLite layout).
(cd "$HERE" && zip -q libv2ray.aar assets/geoip.dat assets/geosite.dat)
echo "Built $HERE/libv2ray.aar"
