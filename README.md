# libcurl-android Build Scripts

This repository contains scripts to build libcurl for Android, statically linked against BoringSSL.

## Prerequisites

*   **Android NDK:** You need the Android NDK installed. The build script requires the path to your NDK installation.
*   **CMake:** Required by both BoringSSL and libcurl build processes.
*   **Ninja:** Used as the build system generator for BoringSSL.
*   **Standard Build Tools:** A working C/C++ compiler toolchain, `bash`, `git`, etc.

## How to Build

1.  **Clone the Repository:**
    ```bash
    git clone --recurse-submodules https://github.com/BugSplat-Git/libcurl-android
    ```

2.  **Configure NDK Path:**
    Edit the `build.sh` script and set the `ANDROID_NDK` variable to the full path of your installed Android NDK.
    ```bash
    # build.sh
    export ANDROID_NDK="/path/to/your/android/ndk"
    ```

3.  **Run the Build Script:**
    Make sure the script is executable and run it:
    ```bash
    chmod +x build.sh
    ./build.sh
    ```

## Build Process

The `build.sh` script performs the following steps:

1.  Exports the `ANDROID_NDK` path.
2.  Validates that the NDK path exists.
3.  Creates a `build/` directory to store the final artifacts.
4.  Copies the `build-boringssl.sh` script into the `boringssl/` subdirectory.
5.  Changes into the `boringssl/` directory.
6.  Executes `build-boringssl.sh` which builds BoringSSL (`libssl.a`, `libcrypto.a`) for the following ABIs:
    *   `armeabi-v7a`
    *   `arm64-v8a`
    *   `x86`
    *   `x86_64`
7.  Copies the resulting BoringSSL build directories (`build_android_*`) into the main `build/boringssl/` directory.
8.  Cleans up the BoringSSL build artifacts and the copied script from the `boringssl/` subdirectory.
9.  Copies the `build-curl.sh` script into the `curl/` subdirectory.
10. Changes into the `curl/` directory.
11. Executes `build-curl.sh` which builds libcurl (statically linked against the previously built BoringSSL) for the same ABIs.
12. Copies the resulting libcurl installation directories (`_install/android/*`) into the main `build/curl/` directory.
13. Cleans up the curl build artifacts (`_build/*`, `_install/*`) and the copied script from the `curl/` subdirectory.

## Output

The final build artifacts (include files and libraries) will be located in the `build/` directory, organized by library and ABI:

*   `build/boringssl/build_android_<ABI>/`
*   `build/curl/<ABI>/` 