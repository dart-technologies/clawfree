# iOS Simulator Architecture Fix (Apple Silicon)

## Issue
Apple Silicon simulators failed to link `ffmpeg_kit_flutter_new` with error:
`Building for 'iOS-simulator', but linking in dylib built for 'iOS'`.

## Root Cause
The binary lacked an `arm64-simulator` slice. Xcode incorrectly linked the device-specific `arm64` slice during simulator builds.

## Permanent Fix: Native arm64-Simulator Support
Transitioned from a Rosetta (`x86_64`) workaround to native `arm64` simulator support via a patched framework build.

### Applied Changes
1.  **Patched Library**:
    - Updated `pubspec.yaml` to use fork `dart-technologies/ffmpeg_kit_flutter` (branch `arm64-simulator-support`).
    - Frameworks were patched using `vtool` to set the build version to platform 7 (`IOSSIMULATOR`).
2.  **Reverted Workarounds**:
    - Removed `arm64` from `EXCLUDED_ARCHS` in project and `.xcconfig` files.
    - Restored default `ONLY_ACTIVE_ARCH` and `SUPPORTED_PLATFORMS` settings.
3.  **Native Pipeline**:
    - Enabled full FFmpeg pipeline in `lib/src/video/itinerary_video_generator.dart` for iOS.
    - Added single-quote escaping for paths in the FFmpeg concat demuxer.

### Maintenance
- **Rebuild**: Run `scripts/rebuild_ffmpeg_arm64_sim.sh rebuild` to clone and patch.
- **Verify**: Run `scripts/rebuild_ffmpeg_arm64_sim.sh verify` to check existing binaries.
