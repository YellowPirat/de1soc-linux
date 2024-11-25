#!/bin/bash
set -euo pipefail

# Check if GPG_KEY is set in environment
if [ -z "${GPG_KEY:-}" ]; then
    echo "ERROR: GPG_KEY environment variable not set"
    echo "Usage: GPG_KEY=your-key-id $0"
    exit 1
fi

# Save starting directory
pushd . > /dev/null

# Configuration
REPO_DIR="../packages"

# Ensure pool/main exists and has packages
if [ ! -d "${REPO_DIR}/pool/main" ] || [ -z "$(ls -A ${REPO_DIR}/pool/main/*.deb 2>/dev/null)" ]; then
    echo "ERROR: No .deb packages found in ${REPO_DIR}/pool/main/"
    echo "Please place your .deb packages in ${REPO_DIR}/pool/main/ first"
    popd > /dev/null
    exit 1
fi

# Create distribution directory structure
mkdir -p "${REPO_DIR}/dists/stable/main/binary-armhf"

# Generate Packages file
pushd "${REPO_DIR}" > /dev/null
echo "Generating Packages file..."
dpkg-scanpackages pool/main > dists/stable/main/binary-armhf/Packages
gzip -k dists/stable/main/binary-armhf/Packages

# Generate and sign Release files
pushd dists/stable > /dev/null
echo "Generating and signing Release files..."
apt-ftparchive release . > Release
gpg --default-key "${GPG_KEY}" -abs -o Release.gpg Release
gpg --default-key "${GPG_KEY}" --clearsign -o InRelease Release
popd > /dev/null  # back to REPO_DIR

echo "Repository creation complete!"
echo "Package contents:"
find pool/main -type f -name "*.deb" -exec basename {} \;
popd > /dev/null  # back to starting directory