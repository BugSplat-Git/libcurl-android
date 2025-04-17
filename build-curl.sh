#!/bin/bash

set -e

# SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# SOURCE_DIR="$SCRIPT_DIR" # Assuming the script is in the curl source root
# WORKSPACE_DIR="$(pwd)" # Assume script is run from the workspace root
# SOURCE_DIR="$WORKSPACE_DIR/curl"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SOURCE_DIR="$SCRIPT_DIR" # Assuming the script is in the curl source root

# --- Configuration ---
DEFAULT_ANDROID_API_LEVEL=29
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
# ---

# --- Argument Parsing ---
if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_android_ndk>"
  echo "You can also set the ANDROID_NDK environment variable."
  if [ -z "$ANDROID_NDK" ]; then
    exit 1
  else
    echo "Using ANDROID_NDK from environment: $ANDROID_NDK"
  fi
else
  export ANDROID_NDK="$1"
  echo "Using ANDROID_NDK from argument: $ANDROID_NDK"
fi

if [ ! -d "$ANDROID_NDK" ]; then
  echo "Error: ANDROID_NDK directory not found: $ANDROID_NDK"
  exit 1
fi

CMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake"
if [ ! -f "$CMAKE_TOOLCHAIN_FILE" ]; then
    echo "Error: CMake toolchain file not found: $CMAKE_TOOLCHAIN_FILE"
    exit 1
fi

ANDROID_API_LEVEL=${ANDROID_API_LEVEL:-$DEFAULT_ANDROID_API_LEVEL}
echo "Using Android API Level: $ANDROID_API_LEVEL"
# ---

echo "Building curl for Android ABIs: ${ABIS[*]}"
echo "Source directory: $SOURCE_DIR"

for ABI in "${ABIS[@]}"; do
  BUILD_DIR="$SOURCE_DIR/_build/android/$ABI"
  INSTALL_DIR="$SOURCE_DIR/_install/android/$ABI"
  # --- Define BoringSSL paths for this ABI ---
  BORINGSSL_BUILD_DIR_FOR_ABI="$SOURCE_DIR/../build/boringssl/build_android_${ABI}"
  BORINGSSL_INCLUDE_DIR="$SOURCE_DIR/../boringssl/include" # Include dir from BoringSSL source
  BORINGSSL_SSL_LIB="${BORINGSSL_BUILD_DIR_FOR_ABI}/ssl/libssl.a"
  BORINGSSL_CRYPTO_LIB="${BORINGSSL_BUILD_DIR_FOR_ABI}/crypto/libcrypto.a"
  # ---

  echo ""
  echo "--------------------------------------------------"
  echo " Building for ABI: $ABI"
  echo " Build directory: $BUILD_DIR"
  echo " Install directory: $INSTALL_DIR"
  echo " Linking BoringSSL from: ${BORINGSSL_BUILD_DIR_FOR_ABI}"
  echo "--------------------------------------------------"

  # Validate that BoringSSL libs exist for this ABI before configuring
  if [ ! -f "$BORINGSSL_SSL_LIB" ] || [ ! -f "$BORINGSSL_CRYPTO_LIB" ]; then
    echo "Error: BoringSSL libraries not found for ABI $ABI at expected locations:" >&2
    echo "  $BORINGSSL_SSL_LIB" >&2
    echo "  $BORINGSSL_CRYPTO_LIB" >&2
    echo "Ensure build-boringssl.sh ran successfully first." >&2
    exit 1
  fi

  mkdir -p "$BUILD_DIR"
  rm -rf "$BUILD_DIR"/* # Clean previous build

  # Use a subshell to avoid polluting the main environment and manage cd
  (
    cd "$BUILD_DIR" && \
    cmake "$SOURCE_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DANDROID_ABI="$ABI" \
        -DANDROID_PLATFORM="android-$ANDROID_API_LEVEL" \
        -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING=OFF \
        -DCURL_ENABLE_SSL=ON \
        -DOPENSSL_USE_STATIC_LIBS=TRUE \
        -DOPENSSL_INCLUDE_DIR="$BORINGSSL_INCLUDE_DIR" \
        -DOPENSSL_SSL_LIBRARY="$BORINGSSL_SSL_LIB" \
        -DOPENSSL_CRYPTO_LIBRARY="$BORINGSSL_CRYPTO_LIB" \
        -DCURL_USE_LIBPSL=OFF && \
    cmake --build . --target install --config Release -j $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
  ) || { echo "Error building for ABI $ABI"; exit 1; }

  echo "Successfully built and installed for ABI: $ABI"
done

echo ""
echo "--------------------------------------------------"
echo "All Android ABIs built successfully!"
echo "Install directories:"
for ABI in "${ABIS[@]}"; do
  echo "  $SOURCE_DIR/_install/android/$ABI"
done
echo "--------------------------------------------------" 