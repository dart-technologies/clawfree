#!/bin/bash

################################################################################
# FFmpeg Kit Flutter - arm64 Simulator Maintenance Script
# This script rebuilds and/or verifies XCFrameworks for arm64 simulator support.
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
echo_success() { echo -e "${GREEN}✓${NC} $1"; }

################################################################################
# Configuration
################################################################################

REPO_URL="https://github.com/sk3llo/ffmpeg_kit_flutter.git"
FORK_NAME="dart-technologies"
WORK_DIR="$(pwd)/ffmpeg_rebuild_workspace"
CLONE_DIR="$WORK_DIR/ffmpeg_kit_flutter"
FRAMEWORKS_DIR="$CLONE_DIR/ios/Frameworks"
VERSION="7.1.1-full-gpl"

################################################################################
# Verification Logic
################################################################################

verify_build() {
    echo ""
    echo "==========================================="
    echo "Verifying arm64 Simulator Support"
    echo "==========================================="
    
    if [ ! -d "$FRAMEWORKS_DIR" ]; then
        echo_error "Frameworks directory not found at $FRAMEWORKS_DIR"
    fi

    TOTAL=0
    PASSED=0

    cd "$FRAMEWORKS_DIR"
    for FRAMEWORK in *.framework; do
        [ -d "$FRAMEWORK" ] || continue
        FRAMEWORK_NAME=$(basename "$FRAMEWORK" .framework)
        TOTAL=$((TOTAL + 1))
        BINARY="$FRAMEWORK/$FRAMEWORK_NAME"
        
        # Check architectures
        ARCHS=$(lipo -info "$BINARY" 2>/dev/null | grep -o "arm64\|x86_64" | sort -u | tr '\n' ' ')
        IS_SIM=$(vtool -show-build "$BINARY" 2>/dev/null | grep -q "platform IOSSIMULATOR" && echo "YES" || echo "NO")
        
        if [[ "$ARCHS" == *"arm64"* ]] && [ "$IS_SIM" = "YES" ]; then
            echo_success "$FRAMEWORK_NAME: arm64-sim OK ($ARCHS)"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}✗${NC} $FRAMEWORK_NAME: Failed (Archs: $ARCHS, Sim: $IS_SIM)"
        fi
    done

    echo "==========================================="
    echo "Results: $PASSED/$TOTAL frameworks verified"
    echo "==========================================="
    [ "$PASSED" -eq "$TOTAL" ] || exit 1
}

################################################################################
# Rebuild Logic
################################################################################

rebuild_all() {
    echo_info "Checking prerequisites..."
    command -v xcodebuild &>/dev/null || echo_error "Xcode not configured"
    command -v git &>/dev/null || echo_error "Git not installed"

    echo_info "Setting up workspace at $WORK_DIR"
    mkdir -p "$WORK_DIR"
    [ -d "$CLONE_DIR" ] && rm -rf "$CLONE_DIR"
    
    echo_info "Cloning and setting up SDK..."
    git clone "$REPO_URL" "$CLONE_DIR"
    cd "$CLONE_DIR"
    git checkout "$VERSION" 2>/dev/null || echo_warn "Using main branch"
    bash scripts/setup_ios.sh

    # Handle unzip location variations
    [ -d "Frameworks" ] && [ ! -d "ios/Frameworks" ] && mv Frameworks ios/

    BUILD_DIR="$WORK_DIR/build"
    mkdir -p "$BUILD_DIR"

    FRAMEWORKS=$(find "$FRAMEWORKS_DIR" -name "*.framework" -type d)
    for FW_PATH in $FRAMEWORKS; do
        FW_NAME=$(basename "$FW_PATH" .framework)
        echo_info "Patching $FW_NAME..."
        
        FW_BUILD_DIR="$BUILD_DIR/$FW_NAME"
        mkdir -p "$FW_BUILD_DIR"
        BINARY="$FW_PATH/$FW_NAME"
        
        lipo "$BINARY" -thin arm64 -output "$FW_BUILD_DIR/arm64"
        vtool -set-build-version 7 12.0 12.0 -replace -output "$FW_BUILD_DIR/arm64-sim" "$FW_BUILD_DIR/arm64"
        
        if lipo -info "$BINARY" | grep -q "x86_64"; then
            lipo "$BINARY" -thin x86_64 -output "$FW_BUILD_DIR/x86_64"
            lipo -create "$FW_BUILD_DIR/arm64-sim" "$FW_BUILD_DIR/x86_64" -output "$BINARY"
        else
            cp "$FW_BUILD_DIR/arm64-sim" "$BINARY"
        fi
    done

    echo_info "Updating Podspec..."
    PODSPEC="$CLONE_DIR/ios/ffmpeg_kit_flutter_new.podspec"
    sed -i '' '/EXCLUDED_ARCHS.*arm64/d' "$PODSPEC"
    
    echo_info "Committing changes to local SDK copy..."
    git add .
    git commit -m "Add arm64 simulator support" || true
    
    verify_build
}

################################################################################
# CLI Entry Point
################################################################################

case "$1" in
    verify)
        verify_build
        ;;
    rebuild)
        rebuild_all
        ;;
    *)
        echo "Usage: $0 {rebuild|verify}"
        echo "  rebuild: Clones, patches, and verifies the SDK"
        echo "  verify:  Checks existing binaries in the workspace"
        exit 1
        ;;
esac
