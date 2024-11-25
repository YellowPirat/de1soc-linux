# DE1-SoC Linux Repository

A Debian package repository that provides pre-built Intel (Altera) SoCFPGA Linux kernels, headers, and device tree blobs for the Terasic DE1-SoC development board. This repository packages the official Intel SoCFPGA Linux kernel (https://github.com/altera-opensource/linux-socfpga) to simplify deployment on DE1-SoC boards.

## Available Packages

- `linux-image-6.6.22-lts-socfpga`: Linux kernel image and modules
- `linux-headers-6.6.22-lts-socfpga`: Kernel headers for module development
- `linux-dtb-6.6.22-lts-socfpga`: Device Tree Blob for Cyclone V SoC
- `linux-image-6.6.22-lts-socfpga-dbg`: Debug symbols for kernel debugging
- `linux-libc-dev`: Linux support headers for userspace development

Currently available kernel version:

- 6.6.22-lts-socfpga

## Installation

1. Add the repository GPG key and source:

    ```bash
    wget -qO - https://yellowpirat.github.io/de1soc-linux/de1soc-linux.gpg | sudo apt-key add -
    echo "deb https://yellowpirat.github.io/de1soc-linux/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/de1soc-linux.list
    ```

2. Update package lists:

    ```bash
    sudo apt update
    ```

3. Install the kernel packages:

    ```bash
    # Install kernel image and DTB
    sudo apt install linux-image-6.6.22-lts-socfpga linux-dtb-6.6.22-lts-socfpga

    # Optional: Install kernel headers for module development
    sudo apt install linux-headers-6.6.22-lts-socfpga

    # Optional: Install debug symbols
    sudo apt install linux-image-6.6.22-lts-socfpga-dbg
    ```

## Repository Maintenance

For repository maintainers:

### Required Tools

```bash
# Install all required dependencies
sudo apt install git make gcc gcc-arm-linux-gnueabihf dpkg-dev bison flex \
    libssl-dev bc rsync lsb-release fakeroot debhelper
```

### Building and Publishing Packages

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

4. Create packages (requires GPG key for signing):

    ```bash
    GPG_KEY="your-gpg-key-here" ./create_packages.sh
    ```

5. Update GitHub Pages:

    - Push your changes to GitHub
    - Run the update script:

    ```bash
    ./update_pages.sh
    ```

## Package Details

### linux-image-6.6.22-lts-socfpga

- Version: 6.6.22-lts-socfpga
- Architecture: armhf
- Size: 6.7 MB
- Description: Contains the Linux kernel, modules and corresponding files

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

## License

- Linux kernel: GPL-2.0 (maintained by Intel)
- Packaging scripts: MIT

## Source

The kernel source code is maintained by Intel at:
https://github.com/altera-opensource/linux-socfpga