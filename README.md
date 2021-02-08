# Re-Animator LTTng - an LTTng fork designed for re-animation

This is the orchestrator for Re-Animator LTTng, an LTTng fork designed for re-animation.

For more information on the Re-Animator project, please see our paper [Re-Animator: Versatile High-Fidelity Storage-System Tracing and Replaying](https://doi.org/10.1145/3383669.3398276).

Re-Animator LTTng is under development by Ibrahim Umit Akgun of the File Systems and Storage Lab (FSL) at Stony Brook University under Professor Erez Zadok.

## Setup

1. Ensure you have the Re-Animator Linux kernel patch installed.
1. Install the following required programs and libraries:
    ```
    asciidoc autoconf automake bison build-essential cmake flex g++ gcc git libaio-dev libboost-dev libboost-program-options-dev libboost-thread-dev libdw-dev libelf-dev libgtk2.0-dev libnuma-dev libpopt-dev libtool libxml2-dev libxml2-dev make perl uuid-dev zlib1g-dev
    ```
    All of the above requirements are available through the APT package manager on Ubuntu 16 and 18.
1. Clone this repository
1. Run `build-reanimator-lttng.sh`
    * Run with `--install-packages` to install any missing packages
1. The `lttng-client` executable will be located under the `build` directory
1. Disable `sudo` prompts. Re-Animator LTTng components call `system(3)` with `sudo`. Alternatively, one may remove all instances of `sudo`, recompile, and run as root.

## Installing Re-Animator Linux Kernel Modifications

1. Clone the [Linux kernel stable tree](https://github.com/gregkh/linux) repository
    ```bash
    git clone https://github.com/gregkh/linux.git
    ```
1. Checkout [version 4.19.51](https://github.com/gregkh/linux/commit/7aa823a959e1f50c0dab9e01c1940235eccc04cc)
    ```bash
    git checkout 7aa823a959e1f50c0dab9e01c1940235eccc04cc
    ```
1. Apply [linux_kernel.patch](https://github.com/SNIA/reanimator-lttng/blob/master/linux_kernel.patch), located at the root of this repository.
    ```bash
    git apply --whitespace=warn linux_kernel.patch
    ```
1. Install the following packages
    ```
    git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison
    ```
1. Install the modified kernel as normal. No changes are required for `make menuconfig`.
    ```bash
    cp /boot/config-$(uname -r) .config
    make menuconfig
    make -j$(nproc)
    sudo make modules_install -j$(nproc)
    sudo make install -j$(nproc)
    ```
1. Restart your machine and confirm your changes
    ```bash
    uname -a
    ```
## Dependencies and Support

Ubuntu 16 and 18 are officially supported.

Re-Animator LTTng depends on forks of LTTng components:
* [reanimator-lttng-ust](https://github.com/SNIA/reanimator-lttng-ust)
* [reanimator-lttng-tools](https://github.com/SNIA/reanimator-lttng-tools)
* [reanimator-lttng-modules](https://github.com/SNIA/reanimator-lttng-modules)

As well as the following Re-Animator components:
* [reanimator-userspace-rcu](https://github.com/SNIA/reanimator-userspace-rcu) - a lockless synchronization method
* [reanimator-babeltrace](https://github.com/SNIA/reanimator-babeltrace) - for trace format conversion
* [reanimator-library](https://github.com/SNIA/reanimator-library) - converts system call traces to DataSeries
* [reanimator-replayer](https://github.com/SNIA/reanimator-replayer) - replays executables from saved traces
* [oneTBB](https://github.com/oneapi-src/oneTBB) - thread building blocks for parallel C++ programs
