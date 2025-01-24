#!/bin/sh

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
    go version

    # Clean up by removing the downloaded tarball
    rm -rf "${TEMP_DIR}/go.tar.gz"
}

# Check if Go is installed
goPath=$(which go)

# If Go is not installed, install it
if [ -z "$goPath" ]; then
    echo "Go is not installed. Installing version ${GO_VERSION}..."
    install_go
else
    echo "Go is already installed at ${goPath}."
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
