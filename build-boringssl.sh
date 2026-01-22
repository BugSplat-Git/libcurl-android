#!/bin/bash
#
# Build BoringSSL for Android with 16KB page size support
# See: https://developer.android.com/guide/practices/page-sizes
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
DEFAULT_ANDROID_API_LEVEL="android-29"
ANDROID_ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

# 16KB page size linker flag for Android 15+ compatibility
# This ensures ELF segments are aligned to 16KB boundaries
PAGE_SIZE_LDFLAGS="-Wl,-z,max-page-size=16384"
# ---

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BORINGSSL_SRC_DIR="$SCRIPT_DIR" # Assuming the script is in the boringssl root

# --- Argument Parsing & NDK Setup ---
if [ -z "$1" ]; then
  echo "Usage: $0 [<path_to_android_ndk>]"
  echo "If <path_to_android_ndk> is not provided, the script will use the ANDROID_NDK environment variable."
  if [ -z "$ANDROID_NDK" ]; then
    echo "Error: Neither command-line argument nor ANDROID_NDK environment variable is set."
    exit 1
  else
    echo "Using ANDROID_NDK from environment: $ANDROID_NDK"
    # ANDROID_NDK is already set
  fi
else
  export ANDROID_NDK="$1" # Export it so CMake toolchain can potentially use it
  echo "Using ANDROID_NDK from argument: $ANDROID_NDK"
fi

# Validate NDK path
if [ ! -d "$ANDROID_NDK" ]; then
  echo "Error: Android NDK directory not found: $ANDROID_NDK"
  exit 1
fi

# Validate CMake toolchain file
CMAKE_TOOLCHAIN_FILE="${ANDROID_NDK}/build/cmake/android.toolchain.cmake"
if [ ! -f "$CMAKE_TOOLCHAIN_FILE" ]; then
    echo "Error: CMake toolchain file not found: $CMAKE_TOOLCHAIN_FILE"
    exit 1
fi
# ---

ANDROID_API_LEVEL=${ANDROID_API_LEVEL:-$DEFAULT_ANDROID_API_LEVEL} # Allow override via env var
echo "Using Android API Level: ${ANDROID_API_LEVEL#android-}" # Print just the number

# Loop through each ABI and build
for ABI in "${ANDROID_ABIS[@]}"; do
  BUILD_DIR="${BORINGSSL_SRC_DIR}/build_android_${ABI}"
  echo ""
  echo "--------------------------------------------------"
  echo "Configuring for ABI: ${ABI}, API Level: ${ANDROID_API_LEVEL#android-}"
  echo "Build directory: ${BUILD_DIR}"
  echo "--------------------------------------------------"

  # Clean previous build directory
  rm -rf "${BUILD_DIR}"
  mkdir -p "${BUILD_DIR}"

  cmake -DANDROID_ABI=${ABI} \
        -DANDROID_PLATFORM=${ANDROID_API_LEVEL} \
        -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TOOLCHAIN_FILE}" \
        -DCMAKE_SHARED_LINKER_FLAGS="${PAGE_SIZE_LDFLAGS}" \
        -DCMAKE_EXE_LINKER_FLAGS="${PAGE_SIZE_LDFLAGS}" \
        -GNinja -B "${BUILD_DIR}" "${BORINGSSL_SRC_DIR}"

  echo "Building for ABI: ${ABI}"
  ninja -C "${BUILD_DIR}"

  echo "Successfully built for ABI: ${ABI}"
done

echo ""
echo "--------------------------------------------------"
echo "Android builds for all ABIs completed successfully."
echo "Output directories:"
for ABI in "${ANDROID_ABIS[@]}"; do
  echo "- ${BORINGSSL_SRC_DIR}/build_android_${ABI}" 
done
echo "--------------------------------------------------" 