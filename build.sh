#!/bin/bash
export ANDROID_NDK="$HOME/Library/Android/sdk/ndk/28.2.13676358"

if [ ! -d "$ANDROID_NDK" ]; then
  echo "Error: The ANDROID_NDK path '$ANDROID_NDK' does not exist or is not a directory. Please set the correct path in build.sh." >&2
  exit 1
fi

mkdir -p build/boringssl
mkdir -p build/curl

cp build-boringssl.sh boringssl
cp build-curl.sh curl

cd boringssl
./build-boringssl.sh # Run without arg, uses exported ANDROID_NDK
cp -r build_android_arm64-v8a ../build/boringssl
cp -r build_android_armeabi-v7a ../build/boringssl
cp -r build_android_x86 ../build/boringssl
cp -r build_android_x86_64 ../build/boringssl
rm -rf build_android_*
cd ..
rm boringssl/build-boringssl.sh

cd curl
./build-curl.sh # Run without arg, uses exported ANDROID_NDK
cp -r _install/android/arm64-v8a ../build/curl
cp -r _install/android/armeabi-v7a ../build/curl
cp -r _install/android/x86 ../build/curl
cp -r _install/android/x86_64 ../build/curl
rm -rf _install/*
rm -rf _build/*
cd ..
rm curl/build-curl.sh
