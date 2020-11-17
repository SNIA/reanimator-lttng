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
    All of the above requirements are available through the APT package manager on Ubuntu 16.
1. Clone this repository
1. Run `build-reanimator-lttng.sh`
    * Run with `--install` to install files and libraries under `/usr/local/`
    * Run with `--install-packages` to install any missing packages
1. The `lttng-client` executable will be located under the `build` directory

## Dependencies and Support

Ubuntu 16 and 18 are officially supported.

Re-Animator LTTng depends on Re-Animator forks of LTTng components:
* [reanimator-lttng-ust](https://github.com/SNIA/reanimator-lttng-ust)
* [reanimator-lttng-tools](https://github.com/SNIA/reanimator-lttng-tools)
* [reanimator-lttng-modules](https://github.com/SNIA/reanimator-lttng-modules)

As well as the following Re-Animator components:
* [reanimator-userspace-rcu](https://github.com/SNIA/reanimator-userspace-rcu) - a lockless synchronization method
* [reanimator-babeltrace](https://github.com/SNIA/reanimator-babeltrace) - for trace format conversion
* [reanimator-library](https://github.com/SNIA/reanimator-library) - converts system call traces to DataSeries
* [reanimator-strace](https://github.com/SNIA/reanimator-strace) - an strace fork compatible with DataSeries
* [oneTBB](https://github.com/oneapi-src/oneTBB) - thread building blocks for parallel C++ programs
