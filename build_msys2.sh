#!/bin/bash

# Dino Windows Build Script for MSYS2
# Based on GitHub Actions workflow

set -e  # Exit on any error

echo "=== Dino Windows Build Script ==="
echo "Starting build process..."

# Check if we're in MSYS2 environment
if [ -z "$MSYSTEM" ]; then
    echo "Error: This script must be run in MSYS2 environment (UCRT64 or CLANG64)"
    echo "Please start MSYS2 terminal and run this script"
    exit 1
fi

echo "Current MSYS2 system: $MSYSTEM"

# Set build environment based on MSYSTEM
case "$MSYSTEM" in
    "UCRT64")
        ENV="ucrt-x86_64"
        ;;
    "CLANG64")
        ENV="clang-x86_64"
        ;;
    *)
        echo "Warning: Unsupported MSYSTEM '$MSYSTEM'. Using ucrt-x86_64 as default."
        ENV="ucrt-x86_64"
        ;;
esac

echo "Using environment: $ENV"

# Function to install packages
install_dependencies() {
    echo "=== Installing dependencies ==="
    
    local packages=(
        "git"
        "make"
        "zip"
        "unzip"
        "curl"
        "mingw-w64-$ENV-toolchain"
        "mingw-w64-$ENV-gcc"
        "mingw-w64-$ENV-cmake"
        "mingw-w64-$ENV-ninja"
        "mingw-w64-$ENV-libsoup3"
        "mingw-w64-$ENV-gtk4"
        "mingw-w64-$ENV-sqlite3"
        "mingw-w64-$ENV-gobject-introspection"
        "mingw-w64-$ENV-glib2"
        "mingw-w64-$ENV-glib-networking"
        "mingw-w64-$ENV-openssl"
        "mingw-w64-$ENV-libgcrypt"
        "mingw-w64-$ENV-libgee"
        "mingw-w64-$ENV-vala"
        "mingw-w64-$ENV-gsettings-desktop-schemas"
        "mingw-w64-$ENV-qrencode"
        "mingw-w64-$ENV-ntldd-git"
        "mingw-w64-$ENV-gpgme"
        "mingw-w64-$ENV-libadwaita"
        "mingw-w64-$ENV-gspell"
        "mingw-w64-$ENV-enchant"
        "mingw-w64-$ENV-hunspell"
        "mingw-w64-$ENV-iso-codes"
        "mingw-w64-$ENV-gst-plugins-base"
        "mingw-w64-$ENV-gst-plugins-good"
        "mingw-w64-$ENV-gst-plugins-bad"
        "mingw-w64-$ENV-cppwinrt"
        "mingw-w64-$ENV-meson"
        "mingw-w64-$ENV-abseil-cpp"
        "mingw-w64-$ENV-webrtc-audio-processing-1"
        "mingw-w64-$ENV-libsignal-protocol-c"
        "mingw-w64-$ENV-fontconfig"
        "mingw-w64-$ENV-protobuf-c"
        "mingw-w64-$ENV-check"
        # Video codecs and acceleration libraries
        "mingw-w64-$ENV-x264"
        "mingw-w64-$ENV-x265"
        "mingw-w64-$ENV-libvpx"
        "mingw-w64-$ENV-libaom"
        "mingw-w64-$ENV-ffmpeg"
        "mingw-w64-$ENV-gst-plugins-ugly"
        "mingw-w64-$ENV-gst-libav"
        # Intel MediaSDK (if available)
        # "mingw-w64-$ENV-intel-mediasdk"  # May not be available in MSYS2
        # Video Acceleration API
        "mingw-w64-$ENV-libva"
        "mingw-w64-$ENV-libvdpau"
        # Additional multimedia libraries
        "mingw-w64-$ENV-opus"
        "mingw-w64-$ENV-libtheora"
        "mingw-w64-$ENV-libvorbis"
        "mingw-w64-$ENV-speex"
        "mingw-w64-$ENV-speexdsp"
        "mingw-w64-$ENV-nsis"
    )
    
    echo "Updating package database..."
    pacman -Syu --noconfirm
    
    echo "Installing build dependencies..."
    # Try to install all packages, but don't fail if some are not available
    for package in "${packages[@]}"; do
        echo "Installing $package..."
        if ! pacman -S --needed --noconfirm "$package" 2>/dev/null; then
            echo "Warning: Could not install $package (may not be available)"
        fi
    done
    
    echo "Dependencies installation completed!"
}

# Function to install libomemo-c
install_libomemo() {
    echo "=== Installing libomemo-c ==="
    
    if [ -d "libomemo-c" ]; then
        echo "Removing existing libomemo-c directory..."
        rm -rf libomemo-c
    fi
    
    echo "Cloning libomemo-c..."
    git clone https://github.com/dino/libomemo-c.git
    
    cd libomemo-c
    echo "Building libomemo-c..."
    meson setup build
    meson compile -C build
    meson install -C build
    cd ..
    
    echo "libomemo-c installed successfully!"
}

# Function to configure the build
configure_build() {
    echo "=== Configuring Dino build ==="
    
    # Create dist directory for installation
    DIST_DIR="$PWD/dist"
    
    # Clean previous build if exists
    if [ -d "build" ]; then
        echo "Removing existing build directory..."
        rm -rf build
    fi
    
    echo "Setting up meson build..."
    meson setup build --prefix="$DIST_DIR" --buildtype=release \
        -Dc_args="-w" \
        -Dcpp_args="-w" \
        -Dvala_args="--disable-warnings"
    
    echo "Build configured successfully!"
}

# Function to build Dino
build_dino() {
    echo "=== Building Dino ==="
    
    # Check if quiet mode is requested
    if [ "$QUIET_MODE" = "true" ]; then
        echo "Compiling in quiet mode..."
        if meson compile -C build -q 2>/dev/null; then
            echo "✓ Compilation successful!"
        else
            echo "✗ Compilation failed. Showing errors:"
            meson compile -C build
            exit 1
        fi
    else
        echo "Compiling (warnings suppressed)..."
        if meson compile -C build -q 2>/dev/null; then
            echo "Compilation successful!"
        else
            echo "Compilation failed. Showing errors:"
            meson compile -C build
        fi
    fi
    
    echo "Dino built successfully!"
}

# Function to create package
create_package() {
    echo "=== Creating Dino package ==="
    
    DEST_FOLDER="$PWD/dist"
    
    echo "Installing to $DEST_FOLDER..."
    meson install -C build
    
    cd "$DEST_FOLDER"
    
    echo "Organizing files..."
    # Move plugins to bin directory
    if [ -d "./lib/dino/plugins" ]; then
        if [ -d "./bin/plugins" ]; then
            echo "Removing existing plugins directory..."
            rm -rf ./bin/plugins
        fi
        mv ./lib/dino/plugins ./bin
        echo "Moved plugins to bin directory"
    else
        echo "No plugins directory found to move"
    fi
    
    echo "Copying system binaries..."
    # Copy required system binaries
    cp /"$MSYSTEM"/bin/gdbus.exe ./bin/ 2>/dev/null || echo "Warning: gdbus.exe not found"
    cp /"$MSYSTEM"/bin/gspawn-win64-helper.exe ./bin/ 2>/dev/null || echo "Warning: gspawn-win64-helper.exe not found"
    
    echo "Copying system libraries and data..."
    # Copy required system directories
    if [ -d "/"$MSYSTEM"/share/xml" ]; then
        cp -r /"$MSYSTEM"/share/xml ./share/ 2>/dev/null || echo "Warning: xml directory not copied"
    fi
    
    if [ -d "/"$MSYSTEM"/lib/enchant-2" ]; then
        cp -r /"$MSYSTEM"/lib/enchant-2 ./lib/ 2>/dev/null || echo "Warning: enchant-2 not copied"
    fi
    
    if [ -d "/"$MSYSTEM"/lib/gstreamer-1.0" ]; then
        cp -r /"$MSYSTEM"/lib/gstreamer-1.0 ./lib/ 2>/dev/null || echo "Warning: gstreamer-1.0 not copied"
    fi
    
    # Copy fonts
    mkdir -p ./etc/fonts
    if [ -d "/"$MSYSTEM"/etc/fonts" ]; then
        cp -r /"$MSYSTEM"/etc/fonts/* ./etc/fonts/ 2>/dev/null || echo "Warning: fonts not copied"
    fi
    
    # Copy GDK pixbuf
    mkdir -p ./lib/gdk-pixbuf-2.0/
    if [ -d "/"$MSYSTEM"/lib/gdk-pixbuf-2.0" ]; then
        cp -r /"$MSYSTEM"/lib/gdk-pixbuf-2.0/* ./lib/gdk-pixbuf-2.0/ 2>/dev/null || echo "Warning: gdk-pixbuf-2.0 not copied"
    fi
    
    # Copy GIO modules
    mkdir -p ./lib/gio/
    if [ -d "/"$MSYSTEM"/lib/gio" ]; then
        cp -r /"$MSYSTEM"/lib/gio/* ./lib/gio/ 2>/dev/null || echo "Warning: gio modules not copied"
    fi
    
    # Copy icons
    mkdir -p ./share/icons
    if [ -d "/"$MSYSTEM"/share/icons" ]; then
        cp -r /"$MSYSTEM"/share/icons/* ./share/icons/ 2>/dev/null || echo "Warning: icons not copied"
    fi
    
    # Copy locales
    mkdir -p ./share/locale
    if [ -d "/"$MSYSTEM"/share/locale" ]; then
        cp -r /"$MSYSTEM"/share/locale/* ./share/locale/ 2>/dev/null || echo "Warning: locales not copied"
    fi
    
    # Copy GLib schemas
    mkdir -p ./share/glib-2.0/schemas
    if [ -d "/"$MSYSTEM"/share/glib-2.0/schemas" ]; then
        cp -r /"$MSYSTEM"/share/glib-2.0/schemas/* ./share/glib-2.0/schemas/ 2>/dev/null || echo "Warning: glib schemas not copied"
    fi
    
    # Copy crypto library
    cp /"$MSYSTEM"/bin/libcrypto-*-x64.dll . 2>/dev/null || echo "Warning: libcrypto not found"
    
    echo "Cleaning up development files..."
    # Remove development files
    rm -rf ./include
    find . -iname "*.dll.a" -exec rm {} +
    
    echo "Copying dependencies..."
    # Convert MSYSTEM to lowercase for path matching
    MSYSTEM_LOWER=$(echo "$MSYSTEM" | tr '[:upper:]' '[:lower:]')
    
    # Copy DLL dependencies using ntldd and ldd
    if command -v ntldd >/dev/null 2>&1; then
        echo "Using ntldd to find dependencies..."
        echo "Finding dependencies for EXE files..."
        find . -iname "*.exe" -exec ntldd {} + 2>/dev/null | grep "$MSYSTEM_LOWER" | awk '{print $1}' | sort -u | while read dll; do
            if [ -f "/$MSYSTEM/bin/$dll" ]; then
                echo "Copying $dll"
                cp "/$MSYSTEM/bin/$dll" . 2>/dev/null || echo "Failed to copy $dll"
            fi
        done
        
        echo "Finding dependencies for DLL files..."
        find . -iname "*.dll" -exec ntldd {} + 2>/dev/null | grep "$MSYSTEM_LOWER" | awk '{print $1}' | sort -u | while read dll; do
            if [ -f "/$MSYSTEM/bin/$dll" ]; then
                echo "Copying $dll"
                cp "/$MSYSTEM/bin/$dll" . 2>/dev/null || echo "Failed to copy $dll"
            fi
        done
        
        # Recursive dependency check for newly copied DLLs
        # echo "Checking recursive dependencies..."
        # for i in {1..3}; do
        #     echo "Dependency check iteration $i..."
        #     find . -iname "*.dll" -exec ntldd {} + 2>/dev/null | grep "$MSYSTEM_LOWER" | awk '{print $1}' | sort -u | while read dll; do
        #         if [ -f "/$MSYSTEM/bin/$dll" ] && [ ! -f "./$dll" ]; then
        #             echo "Copying recursive dependency: $dll"
        #             cp "/$MSYSTEM/bin/$dll" . 2>/dev/null || echo "Failed to copy $dll"
        #         fi
        #     done
        # done
    else
        echo "ntldd not found, skipping ntldd dependency check"
    fi
    
    if command -v ldd >/dev/null 2>&1; then
        echo "Using ldd to find additional dependencies..."
        echo "Finding dependencies for EXE files with ldd..."
        find . -iname "*.exe" -exec ldd {} + 2>/dev/null | grep "$MSYSTEM_LOWER" | awk '{print $1}' | sort -u | while read dll; do
            if [ -f "/$MSYSTEM/bin/$dll" ]; then
                echo "Copying $dll (ldd)"
                cp "/$MSYSTEM/bin/$dll" . 2>/dev/null || echo "Failed to copy $dll"
            fi
        done
        
        echo "Finding dependencies for DLL files with ldd..."
        find . -iname "*.dll" -exec ldd {} + 2>/dev/null | grep "$MSYSTEM_LOWER" | awk '{print $1}' | sort -u | while read dll; do
            if [ -f "/$MSYSTEM/bin/$dll" ]; then
                echo "Copying $dll (ldd)"
                cp "/$MSYSTEM/bin/$dll" . 2>/dev/null || echo "Failed to copy $dll"
            fi
        done
    else
        echo "ldd not found, skipping ldd dependency check"
    fi
    
    echo "Stripping debug symbols..."
    # Strip debug symbols
    find . -iname "*.exe" -exec strip -s {} + 2>/dev/null || true
    find . -iname "*.dll" -exec strip -s {} + 2>/dev/null || true
    
    echo "Moving DLLs to bin directory..."
    # Move DLLs to bin directory
    if ls *.dll 1> /dev/null 2>&1; then
        mv *.dll ./bin/
        echo "DLLs moved to bin directory"
    else
        echo "No DLLs to move"
    fi
    
    cd ..
    
    echo "Package created successfully in $DEST_FOLDER!"
}

# Function to run tests
run_tests() {
    echo "=== Running tests ==="
    
    if meson test -C build; then
        echo "All tests passed!"
    else
        echo "Warning: Some tests failed"
        return 1
    fi
}

# Main execution
main() {
    echo "Starting build process for $ENV..."
    
    # Check for quiet mode
    if [[ " $* " == *" --quiet "* ]]; then
        QUIET_MODE="true"
        echo "Quiet mode enabled"
    fi
    
    # Check if we want to skip dependency installation
    if [[ " $* " == *" --skip-deps "* ]]; then
        echo "Skipping dependency installation..."
    else
        install_dependencies
    fi
    
    # Check if we want to skip libomemo installation
    if [[ " $* " == *" --skip-libomemo "* ]]; then
        echo "Skipping libomemo-c installation..."
    else
        install_libomemo
    fi
    
    configure_build
    build_dino
    create_package

    if [[ " $* " == *" --skip-install "* ]]; then
        echo "Skipping create installation..."
    else
        cd windows-installer/
        cp -r LICENSE LICENSE_SHORT ../dist/* input/
        makensis dino.nsi
        cd ..
    fi

    # Run tests if requested
    if [[ " $* " == *" --test "* ]]; then
        run_tests
    fi
    
    echo ""
    echo "=== Build completed successfully! ==="
    echo "Dino package is available in: $PWD/dist"
    echo "You can run Dino with: ./dist/bin/dino.exe"
    echo ""
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --skip-deps      Skip installation of dependencies"
    echo "  --skip-libomemo  Skip installation of libomemo-c"
    echo "  --test           Run tests after build"
    echo "  --quiet          Suppress warnings and verbose output"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full build with all dependencies"
    echo "  $0 --skip-deps       # Build without installing dependencies"
    echo "  $0 --test            # Build and run tests"
    echo "  $0 --quiet           # Quiet build with suppressed warnings"
    echo "  $0 --skip-deps --skip-libomemo --quiet  # Quick quiet build"
    echo ""
}

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Run main function
main "$@"
