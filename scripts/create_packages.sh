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
dpkg-scanpackages --arch armhf pool/main > dists/stable/main/binary-armhf/Packages
gzip -k dists/stable/main/binary-armhf/Packages

# Generate and sign Release files
pushd dists/stable > /dev/null
echo "Generating and signing Release files..."

# Generate configuration for Release file
cat > Release.conf <<EOF
Dir {
  ArchiveDir ".";
  OverrideDir "";
  CacheDir "";
};

TreeDefault {
  Directory "pool/";
};

BinDirectory "pool/main" {
  Packages "main/binary-armhf/Packages";
  BinOverride "";
  Extra {
    Built-Using "";
  };
};

Default {
  Packages {
    Extensions ".deb";
    Compress ". gzip";
  };
};

APT::FTPArchive::Release {
  Origin "DE1-SoC Linux Repository";
  Label "DE1-SoC Linux";
  Suite "stable";
  Codename "stable";
  Version "6.6.22-lts-socfpga";
  Architectures "armhf";
  Components "main";
  Description "Pre-built Intel SoCFPGA Linux kernels for DE1-SoC";
  NotAutomatic "yes";
  ButAutomaticUpgrades "yes";
};
EOF

# Generate Release file without timestamp-related fields
apt-ftparchive -c=Release.conf release . > Release

# Sign the Release file
gpg --default-key "${GPG_KEY}" -abs -o Release.gpg Release
gpg --default-key "${GPG_KEY}" --clearsign -o InRelease Release

# Cleanup
rm Release.conf

popd > /dev/null # back to REPO_DIR
echo "Repository creation complete!"
echo "Package contents:"
find pool/main -type f -name "*.deb" -exec basename {} \;
sleep 1
popd > /dev/null # back to starting directory