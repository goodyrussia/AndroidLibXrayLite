# AndroidLibXrayLite — permissive-core build (v26.1.23-p1)

2dust's AndroidLibXrayLite wrapper bound against **Xray-core `v1.260123.0-patch.1`**
(eichgee's permissive TLS line) instead of official XTLS.

## Why

Official XTLS v26.1.31+ **removed `allowInsecure`** (config hard-error, replacement
`pinnedPeerCertSha256`/`verifyPeerCertByName`) and v26.7.11+ **bans plain VLESS/Trojan**
to public hosts (`validateOutboundTransportSecurity`). This build keeps the whole
old freedom set:

- `allowInsecure: true` fully honored (one deprecation log line, cosmetic)
- plain (no-TLS) VLESS/Trojan to any address loads and connects
- everything else from 26.1.x: Hysteria2, TUN, VLESS xorMode/padding, VMess detour,
  SS `none` cipher, `udpOverTcp`, sockopt `domainStrategy`/`dialerProxy`

## API deltas vs upstream wrapper (all documented in code)

| Upstream API | This build |
|---|---|
| `RegisterProcessFinder` | kept, **no-op** (core predates `common/net.RegisterAndroidProcessFinder`) — per-UID routing attribution inactive |
| `browser_dialer.Reload()` | not in core; `ReconcileBrowserDialer` keeps the env write, applies on next core start |
| `stats.VisitCounters` | ported via concrete `app/stats.Manager` type assertion (same behavior) |
| `x/mobile/asset` fallback | replaced by `xray.location.asset` dir lookup (the app extracts AAR assets there first) |

Everything else (`InitCoreEnv`, `NewCoreController`, `CheckVersionX`,
`MeasureOutboundDelay`, `FetchTlsCertSha256`, `FetchQuicCertSha256`) is upstream-identical.

## Build

**CRITICAL — use the upstream `build_shared.py` pipeline, not a plain `gomobile bind`.**
Root-mode clients (AsteriskNG `asteriskd`) exec `nativeLibraryDir/libxray.so` as the
core process. That launcher is only produced by `scripts/build_shared.py`, which also
builds `libgojni.so` with the `AndroidXrayCLI_v1` export. A gomobile-bind-only AAR
looks fine but breaks every ROOT mode with `setupErrno=2` (ENOENT).

`scripts/build_aar.sh` (needs Go + Android NDK/SDK):

- clones `github.com/eichgee/Xray-core` at `v1.260123.0-patch.1`
- injects `libv2ray_*.go` (this repo) as `libv2ray/` package inside the core module
  (builds against the core's own dep set — zero version drift)
- runs `build_shared.py --arch arm64` → `libgojni.so` (JNI+CLI) + `libxray.so` launcher
- bundles `assets/geoip.dat` + `geoip.dat`/`geosite.dat` + `geoip-only-cn-private.dat`

Provenance of `v26.1.23-p2`: built 2026-10-05 with the pipeline above (verified:
launcher = aarch64 PIE exec, `AndroidXrayCLI_v1` exported). `p1` was a gomobile-bind-only
build that MISSED the launcher — do not use it for ROOT modes.
