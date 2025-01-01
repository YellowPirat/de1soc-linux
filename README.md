# DE1-SoC Linux Repository

A Debian package repository providing pre-built Intel (Altera) SoCFPGA Linux kernels and additional drivers for the Terasic DE1-SoC development board.

## Available Packages

### Kernel Packages

- `linux-image-6.6.22-lts-socfpga`: Linux kernel image and modules
- `linux-headers-6.6.22-lts-socfpga`: Kernel headers for module development
- `linux-dtb-6.6.22-lts-socfpga`: Device Tree Blob for Cyclone V SoC
- `linux-image-6.6.22-lts-socfpga-dbg`: Debug symbols for kernel debugging
- `linux-libc-dev`: Linux support headers for userspace development

### Driver Packages

- `yp-can-dkms`: CAN bus driver module (DKMS package)

## Installation

### 1. Add Repository

```bash
wget -qO - https://yellowpirat.github.io/de1soc-linux/de1soc-linux.gpg | sudo apt-key add -
echo "deb https://yellowpirat.github.io/de1soc-linux/packages stable main" | \
sudo tee /etc/apt/sources.list.d/de1soc-linux.list
```

### 2. Configure DTB Post-Install Script

Before installing the kernel package, create the following post-install script:

```bash
sudo mkdir -p /etc/kernel/postinst.d
cat > /etc/kernel/postinst.d/copy-dtb <<'EOF'
#!/bin/sh
set -e
version="$1"
image="$2"
if [ -f "/sys/firmware/devicetree/base/compatible" ]; then
    compat=$(cat /sys/firmware/devicetree/base/compatible | tr '\0' '\n' | head -1)
    dtb_name=$(echo "$compat" | sed 's/altr,/socfpga_/').dtb
    dtb_path="/lib/linux-image-${version}/${dtb_name}"
    if [ -f "$dtb_path" ]; then
        cp "$dtb_path" "/boot/dtb"
    fi
fi
EOF
sudo chmod +x /etc/kernel/postinst.d/copy-dtb
```

### 3. Update and Install

```bash
sudo apt update

# Install kernel
sudo apt install linux-image-6.6.22-lts-socfpga

# Optional: Install kernel headers for module development / dkms
sudo apt install linux-headers-6.6.22-lts-socfpga

# Optional: Install CAN driver
sudo apt install yp-can-dkms

# Optional: Install debug symbols
sudo apt install linux-image-6.6.22-lts-socfpga-dbg
```

## Repository Maintenance

For repository maintainers:

### Required Tools

```bash
# Install required dependencies
sudo apt install dpkg-dev apt-utils gpg
```

### Repository Management

The repository follows a simple structure:

```text
packages/
├── pool/
│   └── main/          # All .deb packages go here
└── dists/
    └── stable/
        └── main/
            ├── binary-all/    # Architecture independent packages
            └── binary-armhf/  # ARM hardware float packages
```

To update the repository:

1. Add packages:

    ```bash
    # Create structure if it doesn't exist
    mkdir -p packages/pool/main
    mkdir -p packages/dists/stable/main/binary-all
    mkdir -p packages/dists/stable/main/binary-armhf

    # Copy packages
    cp *.deb packages/pool/main/
    ```

2. Generate package indices:

    ```bash
    cd packages
    dpkg-scanpackages --arch all pool/main > dists/stable/main/binary-all/Packages
    gzip -k dists/stable/main/binary-all/Packages

    dpkg-scanpackages --arch armhf pool/main > dists/stable/main/binary-armhf/Packages
    gzip -k dists/stable/main/binary-armhf/Packages
    ```

3. Create and sign Release file:

    ```bash
    cd dists/stable
    apt-ftparchive -o APT::FTPArchive::Release::Origin="DE1-SoC Linux Repository" \
                -o APT::FTPArchive::Release::Label="DE1-SoC Linux" \
                -o APT::FTPArchive::Release::Suite="stable" \
                -o APT::FTPArchive::Release::Architectures="all armhf" \
                -o APT::FTPArchive::Release::Components="main" \
                release . > Release

    # Sign the release file
    gpg --default-key "YOUR-GPG-KEY" -abs -o Release.gpg Release
    gpg --default-key "YOUR-GPG-KEY" --clearsign -o InRelease Release
    ```

4. Publish the repository:

    ```bash
    git add -f packages/
    git commit -m "Update package repository $(date +%Y-%m-%d)"
    git push
    ```

### Building Kernel Packages

1. Clone the repository:

    ```bash
    git clone https://github.com/yellowpirat/de1soc-linux.git
    cd de1soc-linux/scripts
    ```

2. (Optional) Modify build parameters:

    - Edit `build_kernel.sh` if you need to change kernel version or other build parameters

3. Build the kernel:

    ```bash
    ./build_kernel.sh
    ```

The script will automatically:

- Clone the Intel SoCFPGA Linux repository
- Configure it for DE1-SoC
- Build the kernel and packages
- Generate all required .deb files

## Package Details

### linux-image-6.6.22-lts-socfpga

- Version: 6.6.22-lts-socfpga
- Architecture: armhf
- Size: 6.7 MB
- Description: Linux kernel, modules and corresponding files

### linux-headers-6.6.22-lts-socfpga

- Version: 6.6.22-lts-socfpga
- Architecture: armhf
- Size: 8.0 MB
- Description: Kernel header files for building external modules

### linux-dtb-6.6.22-lts-socfpga

- Version: 6.6.22-lts-socfpga
- Architecture: armhf
- Size: 5.6 KB
- Description: Device Tree Blob file for the Cyclone V SoC Development Kit

### linux-image-6.6.22-lts-socfpga-dbg

- Version: 6.6.22-lts-socfpga
- Architecture: armhf
- Size: 51.6 MB
- Description: Debug symbols for kernel debugging

### linux-libc-dev

- Version: 6.6.22-lts-socfpga
- Architecture: armhf
- Size: 1.2 MB
- Description: Linux support headers for userspace development

### yp-can-dkms

- Version: 1.0.0
- Architecture: all
- Description: CAN bus driver module (DKMS)
- Dependencies: dkms, linux-headers-6.6.22-lts-socfpga

## License

- Linux kernel: GPL-2.0 (maintained by Intel)
- yp-can-dkms: GPL-2.0+
- Repository tools and scripts: MIT

## Source

- Kernel source: [https://github.com/altera-opensource/linux-socfpga](https://github.com/altera-opensource/linux-socfpga)
