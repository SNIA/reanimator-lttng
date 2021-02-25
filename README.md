# Re-Animator LTTng - an LTTng fork designed for re-animation

This is the orchestrator for Re-Animator LTTng, an LTTng fork designed for re-animation.

For more information on the Re-Animator project, please see our paper [Re-Animator: Versatile High-Fidelity Storage-System Tracing and Replaying](https://doi.org/10.1145/3383669.3398276).

Re-Animator LTTng is under development by Ibrahim Umit Akgun of the File Systems and Storage Lab (FSL) at Stony Brook University under Professor Erez Zadok.

## Table of Contents

- [Setup](#Setup)
  - [Installing Re-Animator Linux Kernel Modifications](#Installing-Re-Animator-Linux-Kernel-Modifications)
  - [Install Re-Animator LTTng](#Install-Re-Animator-LTTng)
- [Usage](#Usage)
- [Example](#Example)
- [Contribute Traces to IOTTA](#Contribute-Traces-to-IOTTA)
- [Dependencies and Support](#Dependencies-and-Support)

## Setup

### Installing Re-Animator Linux Kernel Modifications

Re-Animator LTTng requires Linux kernel modifications to function. We recommend allocating at least 25 GiB of disk space before beginning the installation process.

1. Clone the [Linux kernel stable tree](https://github.com/gregkh/linux) repository.
    ```bash
    git clone https://github.com/gregkh/linux.git
    cd linux
    ```
1. Checkout [version 4.19.51](https://github.com/gregkh/linux/commit/7aa823a959e1f50c0dab9e01c1940235eccc04cc)
    ```bash
    git checkout 7aa823a959e1f50c0dab9e01c1940235eccc04cc
    ```
1. Download [linux_kernel.patch](https://github.com/SNIA/reanimator-lttng/blob/master/linux_kernel.patch). Alternatively, the patch can be copied over from the root of this repository.
    ```bash
    wget https://raw.githubusercontent.com/SNIA/reanimator-lttng/master/linux_kernel.patch
    ```
1. Apply the kernel patch. Ignore any whitespace errors that may occur—they do not affect whether or not the patch is successfully applied.
    ```bash
    git apply linux_kernel.patch
    ```
1. Install the following packages
    ```
    git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison
    ```
1. Install the modified kernel as normal. No changes are required for `make menuconfig`
    ```bash
    cp /boot/config-$(uname -r) .config
    make menuconfig
    make -j$(nproc)
    sudo make modules_install -j$(nproc)
    sudo make install -j$(nproc)
    ```
1. Restart your machine
    ```
    sudo reboot
    ```
1. Confirm that you now have Linux version `4.19.51+` installed
    ```bash
    uname -a
    ```

### Install Re-Animator LTTng

1. Ensure you have the Re-Animator Linux kernel patch installed. To install the Re-Animator Linux kernel patch, visit the [Installing Re-Animator Linux Kernel Modifications](#Installing-Re-Animator-Linux-Kernel-Modifications) section
1. Install the following required programs and libraries:
    ```
    asciidoc autoconf automake bison build-essential cmake flex g++ gcc git libaio-dev libboost-dev libboost-program-options-dev libboost-thread-dev libdw-dev libelf-dev libgtk2.0-dev libnuma-dev libpopt-dev libtool libxml2-dev libxml2-dev make perl uuid-dev zlib1g-dev
    ```
    All of the above requirements are available through the APT package manager on Ubuntu 16 and 18.
1. Clone this repository
    ```bash
    git clone https://github.com/SNIA/reanimator-lttng.git
    cd reanimator-lttng
    ```
1. Build Re-Animator LTTng with `build-reanimator-lttng.sh`. Run with `--install-packages` to install any missing packages
    ```bash
    ./build-reanimator-lttng.sh
    ```
1. Disable `sudo` prompts. Alternatively, one may remove all instances of `sudo`, recompile, and run as root. Re-Animator LTTng components call `system(3)` with `sudo`, and thus cannot function correctly without `sudo` prompts disabled.
1. The `lttng-client` executable will be located under the `build` directory

## Usage

```
Generic options:
  -h [ --help ]                   lttng-client [-s, -d] -e [COMMAND]

Configuration:
  -v [ --verbose ]                prints execution logs
  -s [ --session-directory ] arg  lttng session directory path
  -e [ --exec ] arg               executable string which is going to be run 
                                  through lttng
  -d [ --ds-output ] arg          ds output file path
```

## Example

In this example, we trace and replay `/bin/ls` in the Re-Animator LTTng build directory.

### Tracing
```bash
$ ./lttng-client -s /tmp/session-capture/ -d /tmp/ls-example.ds -e /bin/ls
CMakeCache.txt  Makefile  cmake_install.cmake  lttng-client.log   oneTBB                 reanimator-library        reanimator-lttng-tools  reanimator-replayer       report.txt
CMakeFiles      Tests     lttng-client         lttng-read-buffer  reanimator-babeltrace  reanimator-lttng-modules  reanimator-lttng-ust    reanimator-userspace-rcu
>>>>>>>>>>>    babeltrace timing                       :    176  
>>>>>>>>>>>    tracing total timing                    :    933  
>>>>>>>>>>>    tracing just for execution period timing:    7    
```

### Replaying
```bash
$ reanimator-replayer/build/system-call-replayer /tmp/ls-example.ds 
CMakeCache.txt  Makefile  cmake_install.cmake  lttng-client.log   oneTBB                 reanimator-library        reanimator-lttng-tools  reanimator-replayer       report.txt
CMakeFiles      Tests     lttng-client         lttng-read-buffer  reanimator-babeltrace  reanimator-lttng-modules  reanimator-lttng-ust    reanimator-userspace-rcu
```

## Contribute Traces to IOTTA

We strongly encourage you to submit traces taken with Re-Animator LTTng to the SNIA IOTTA Repository. For more information, visit [FAQs for Contributing Trace Files](http://iotta.snia.org/faqs/contribute_traces).

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
