# iOS Simulator Architecture Fix (Apple Silicon)

## Issue
The "iPhone 17 Pro" simulator (running on arm64 Mac Mini) failed to run the app with a linker error:
`Building for 'iOS-simulator', but linking in dylib built for 'iOS'`.

### Root Cause
The `ffmpeg_kit_flutter_new` library uses a "fat" framework that contains an `arm64` slice for physical devices but lacks an `arm64-simulator` slice. On Apple Silicon Macs, Xcode attempts to build a native `arm64` simulator binary and incorrectly tries to link the device-specific `arm64` FFmpeg slice, causing the failure.

## Proposed Fix: Forced Rosetta (x86_64) Build
To resolve this for the hackathon without switching library variants, we force the simulator to run via **Rosetta 2** using the `x86_64` architecture.

### Applied Changes
1.  **Excluded arm64 for Simulators**:
    - Updated `ios/Runner.xcodeproj/project.pbxproj` to set `"EXCLUDED_ARCHS[sdk=iphonesimulator*]" = arm64`.
    - Updated `ios/Flutter/Debug.xcconfig` and `Release.xcconfig` to include `arm64` in `EXCLUDED_ARCHS`.
2.  **Disabled "Build Active Architecture Only"**:
    - Set `ONLY_ACTIVE_ARCH = NO` in project settings and `Podfile` to ensure the `x86_64` slice is built on `arm64` hosts.
3.  **Restored Simulator Destinations**:
    - Updated `SUPPORTED_PLATFORMS` to `"iphonesimulator iphoneos"` to ensure simulators are visible in Xcode/Flutter device lists.
4.  **Podfile Post-Install Hook**:
    - Added logic to `ios/Podfile` to propagate these architecture exclusions and the `iOS 15.0` deployment target to all plugin dependencies.

## Alternative: Temporarily Disabling FFmpeg (Native arm64)
If Rosetta 2 is not working or native performance is required, FFmpeg can be disabled to allow a pure `arm64` build.

### Steps to Disable
1.  **pubspec.yaml**: Comment out `ffmpeg_kit_flutter_new`.
2.  **Code Stubbing**: Replace logic in `lib/src/video/itinerary_video_generator.dart` with stubs to remove the dependency on `package:ffmpeg_kit_flutter_new`.
3.  **Revert Architectures**: Remove `arm64` from `EXCLUDED_ARCHS` in all config files and the `Podfile`.
4.  **Clean & Install**: Run `flutter clean` and `pod install` to remove the offending binary from the workspace.

### Trade-off
- **Pros**: Native `arm64` simulator performance; no Rosetta dependency.
- **Cons**: Video generation features (e.g., Travel Itinerary previews) will be unavailable.
