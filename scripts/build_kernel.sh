#!/bin/bash
set -euo pipefail

# Save starting directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Configuration
KERNEL_VERSION="6.6.22-lts"
KERNEL_SUFFIX="socfpga"
FULL_VERSION="${KERNEL_VERSION}-${KERNEL_SUFFIX}"
GITHUB_REPO="https://github.com/altera-opensource/linux-socfpga.git"
BRANCH="socfpga-${KERNEL_VERSION}"
CROSS_COMPILE="arm-linux-gnueabihf-"
ARCH="arm"
# Calculate optimal number of build jobs (1.5x cores, rounded down)
NPROC=$(nproc)
BUILD_JOBS=$(( (NPROC * 3) / 4 ))
DTB_NAME="socfpga_cyclone5_socdk"

# Package maintainer info (can be overridden by environment variables)
DEBFULLNAME="${DEBFULLNAME:-Ahmet Emirhan Göktaş}"
DEBEMAIL="${DEBEMAIL:-emirhangoktas01@gmail.com}"

# Export for dpkg-buildpackage
export DEBFULLNAME DEBEMAIL

# Directory structure
BUILD_DIR="${REPO_ROOT}/build"
KERNEL_BUILD_DIR="${BUILD_DIR}/kernel"
KERNEL_SOURCE_DIR="${KERNEL_BUILD_DIR}/linux-${FULL_VERSION}"
OUTPUT_DIR="${REPO_ROOT}/packages/pool/main"

# Print configuration
echo "Build configuration:"
echo "- Number of CPU cores: ${NPROC}"
echo "- Build jobs: ${BUILD_JOBS}"
echo "- Package maintainer: ${DEBFULLNAME} <${DEBEMAIL}>"
echo "- Kernel version: ${FULL_VERSION}"

# Required packages (used for installation command)
INSTALL_PACKAGES=(
    "git"
    "make"
    "gcc"
    "gcc-arm-linux-gnueabihf"
    "dpkg-dev"
    "bison"
    "flex"
    "libssl-dev"
    "bc"
    "rsync"
    "lsb-release"
    "fakeroot"
    "debhelper"
)

# Required commands/tools to check (including those provided by packages)
REQUIRED_TOOLS=(
    "git"
    "make"
    "gcc"
    "arm-linux-gnueabihf-gcc"
    "dpkg-buildpackage"
    "dpkg-parsechangelog"
    "bison"
    "flex"
    "bc"
    "rsync"
    "lsb_release"
    "fakeroot"
    "dh"
)

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a package is installed (for non-executables)
package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q '^ii'
}

# Function to check required tools and packages
check_requirements() {
    local missing_commands=()
    local missing_packages=()

    echo "Checking build requirements..."
    
    # Check for libssl-dev specifically
    if ! package_installed "libssl-dev"; then
        missing_packages+=("libssl-dev")
    fi

    # Check each required tool
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command_exists "$tool"; then
            case $tool in
                "dpkg-buildpackage"|"dpkg-parsechangelog")
                    missing_commands+=("$tool (package: dpkg-dev)");;
                "arm-linux-gnueabihf-gcc")
                    missing_commands+=("$tool (package: gcc-arm-linux-gnueabihf)");;
                "dh")
                    missing_commands+=("$tool (package: debhelper)");;
                "lsb_release")
                    missing_commands+=("$tool (package: lsb-release)");;
                *)
                    missing_commands+=("$tool (package: $tool)");;
            esac
        fi
    done

    # If we found missing requirements, print them and exit
    if [ ${#missing_commands[@]} -ne 0 ] || [ ${#missing_packages[@]} -ne 0 ]; then
        echo "ERROR: Missing required tools/packages:"
        
        if [ ${#missing_commands[@]} -ne 0 ]; then
            echo "Missing commands:"
            printf '  - %s\n' "${missing_commands[@]}"
        fi
        
        if [ ${#missing_packages[@]} -ne 0 ]; then
            echo "Missing packages:"
            printf '  - %s\n' "${missing_packages[@]}"
        fi
        
        echo -e "\nPlease install missing packages with:"
        echo "sudo apt install ${INSTALL_PACKAGES[*]}"
        exit 1
    fi

    echo "All required packages are installed."
}

# Function to prepare build environment
prepare_environment() {
    echo "Creating build and output directories..."
    mkdir -p "${OUTPUT_DIR}" "${KERNEL_BUILD_DIR}"
    
    if [ -d "${KERNEL_SOURCE_DIR}" ]; then
        echo "Cleaning existing kernel source directory..."
        rm -rf "${KERNEL_SOURCE_DIR}"
    fi
}

# Function to clone kernel source
clone_kernel() {
    echo "Cloning kernel source..."
    pushd "${KERNEL_BUILD_DIR}" > /dev/null
    git clone --depth=1 -b "${BRANCH}" "${GITHUB_REPO}" "$(basename "${KERNEL_SOURCE_DIR}")"
    popd > /dev/null
}

prepare_sysroot() {
    local SYSROOT="${BUILD_DIR}/sysroot"
    mkdir -p "${SYSROOT}"

    # Use debootstrap to create minimal sysroot
    sudo debootstrap --foreign --arch=armhf bookworm "${SYSROOT}"
    sudo cp /usr/bin/qemu-arm-static "${SYSROOT}/usr/bin/"
    sudo chroot "${SYSROOT}" /debootstrap/debootstrap --second-stage

    # Set environment variables for the build
    export QEMU_LD_PREFIX="${SYSROOT}"
}

build_kernel() {
    prepare_sysroot

    echo "Building kernel..."
    pushd "${KERNEL_SOURCE_DIR}" > /dev/null
    
    local make_opts=(
        "ARCH=${ARCH}"
        "CROSS_COMPILE=${CROSS_COMPILE}"
        "-j${BUILD_JOBS}"
        "CONFIG_LOCALVERSION_AUTO=n"
        "LOCALVERSION=-${KERNEL_SUFFIX}"
        "KDEB_PKGVERSION=${FULL_VERSION}"
        "KERNELRELEASE=${FULL_VERSION}"
        "HOSTCC=${CROSS_COMPILE}gcc"
    )
    
    echo "Configuring kernel..."
    make "${make_opts[@]}" socfpga_defconfig
    
    echo "Building kernel packages..."
    make "${make_opts[@]}" deb-pkg
    
    # Cleanup
    sudo rm -rf "${BUILD_DIR}/sysroot"

    popd > /dev/null
}

# Function to move packages to output directory
move_packages() {
    echo "Moving packages to output directory..."
    pushd "${KERNEL_BUILD_DIR}" > /dev/null
    mv *.deb "${OUTPUT_DIR}/"
    popd > /dev/null
}

# Function to cleanup
cleanup() {
    echo "Cleaning up build directory..."
    rm -rf "${KERNEL_SOURCE_DIR}"
}

# Main execution
main() {
    echo "Starting kernel build process for version ${FULL_VERSION}..."
    
    check_requirements
    prepare_environment
    clone_kernel
    build_kernel
    move_packages
    
    if [ "${CLEAN_BUILD:-false}" = "true" ]; then
        cleanup
    fi
    
    echo "Build complete! Packages have been placed in ${OUTPUT_DIR}"
    ls -l "${OUTPUT_DIR}"/*.deb
}

# Run main function
main