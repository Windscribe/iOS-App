#!/bin/sh

# Skip this script when running SwiftUI previews
if [ "$XCODE_RUNNING_FOR_PREVIEWS" == "1" ]; then
    echo "Skipping WireGuardTunnel for SwiftUI Previews"
    exit 0
fi



# If sdk root marker exists No rebuild it needed.
check_and_save_sdkroot() {
    local sdkroot_marker_file="$BUILD_DIR/sdkroot_marker.txt"
    local current_sdkroot="$SDKROOT"

    # If the marker file exists, compare the saved SDKROOT with the current one
    if [ -f "$sdkroot_marker_file" ]; then
        SAVED_SDKROOT=$(cat "$sdkroot_marker_file")
        if [ "$SAVED_SDKROOT" == "$current_sdkroot" ]; then
            echo "SDKROOT has not changed. Skipping build."
            return 0
        else
            echo "SDKROOT has changed. Proceeding with build. $SAVED_SDKROOT $current_sdkroot"
            echo "$current_sdkroot" > "$sdkroot_marker_file"
            return 1
        fi
    else
        # If the marker file does not exist, save the current SDKROOT
        echo "$current_sdkroot" > "$sdkroot_marker_file"
        echo "SDKROOT saved. Proceeding with build."
        return 1
    fi
}
check_and_save_sdkroot
SDKROOT_RESULT=$?

# If SDKROOT hasn't changed (SDKROOT_RESULT == 0), skip build
if [ $SDKROOT_RESULT -eq 0 ]; then
    exit 0
fi



# build_wireguard_go_bridge.sh - Builds WireGuardKitGo
#
# Figures out the directory where the wireguard-apple SPM package
# is checked out by Xcode (so that it works when building as well as
# archiving), then cd-s to the WireGuardKitGo directory
# and runs make there.

# Check if Go version is provided
if [ -z "$1" ]; then
    echo "Error: Go version not specified."
    echo "Usage: $0 <go_version>"
    exit 1
fi

GO_VERSION=$1

# Function to install Go in a temporary directory
install_go() {
    TEMP_DIR=$(mktemp -d)

    # Determine the Go binary URL for macOS arm64
    GO_TAR_URL="https://golang.org/dl/go${GO_VERSION}.darwin-arm64.tar.gz"

    # Download the Go archive
    echo "Downloading Go version ${GO_VERSION} for macOS arm64..."
    curl -Lo "${TEMP_DIR}/go.tar.gz" "$GO_TAR_URL"

    # Extract the Go archive to the temporary directory
    echo "Extracting Go version ${GO_VERSION}..."
    tar -C "$TEMP_DIR" -xzf "${TEMP_DIR}/go.tar.gz"

    # Set the Go path temporarily
    export PATH="${TEMP_DIR}/go/bin:$PATH"

    # Verify the Go installation
    go version || {
        echo "Error: Failed to install Go."
        exit 1
    }

    # Clean up by removing the downloaded tarball
    rm -rf "${TEMP_DIR}/go.tar.gz"
}

# Check if Go is installed and has the correct version
current_go_version=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')

if [ "$current_go_version" == "$GO_VERSION" ]; then
    echo "Correct Go version (${GO_VERSION}) is already installed. Skipping installation."
else
    echo "Go version mismatch (found: $current_go_version, expected: $GO_VERSION). Installing correct version..."
    install_go
fi

# Proceed with the WireGuard build process
project_data_dir="$BUILD_DIR"

# The wireguard-apple README suggests using ${BUILD_DIR%Build/*}, which
# doesn't seem to work. So here, we do the equivalent in script.

while true; do
    parent_dir=$(dirname "$project_data_dir")
    basename=$(basename "$project_data_dir")
    project_data_dir="$parent_dir"
    if [ "$basename" = "Build" ]; then
        break
    fi
done

# The wireguard-apple README looks into
# SourcePackages/checkouts/wireguard-apple, but Xcode seems to place the
# sources in SourcePackages/checkouts/ so just playing it safe and
# trying both.

checkouts_dir="$project_data_dir"/SourcePackages/checkouts
if [ -e "$checkouts_dir"/wireguard-apple ]; then
    checkouts_dir="$checkouts_dir"/wireguard-apple
fi

wireguard_go_dir="$checkouts_dir"/Sources/WireGuardKitGo

# Ensure Go is in the path, we append it to the PATH variable
export PATH="${PATH}:/usr/local/bin:$goPath"

# Change to the WireGuardKitGo directory and run `make`
cd "$wireguard_go_dir" && /usr/bin/make || {
    echo "Error: Make failed in $wireguard_go_dir"
    exit 1
}

# Saved last sdk used to built it.
echo "$SDKROOT" > "$BUILD_DIR/sdkroot_marker.txt"

echo "WireGuardGoBridge successfully built."
