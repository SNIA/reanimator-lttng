# FSL LTTng - an LTTng fork designed for re-animation

This is the orchestrator for FSL LTTng, an LTTng fork designed for re-animation.

For more information on the Re-Animator project, please see our paper [Re-Animator: Versatile High-Fidelity Storage-System Tracing and Replaying](https://doi.org/10.1145/3383669.3398276).

FSL LTTng is under development by Ibrahim Umit Akgun of the File Systems and Storage Lab (FSL) at Stony Brook University under Professor Erez Zadok.

## Dependencies

Currently, only Ubuntu 16 is officially supported.

FSL-LTTng depends on FSL forks of LTTng components:
* [lttng-ust](https://github.com/sbu-fsl/lttng-ust)
* [lttng-tools](https://github.com/sbu-fsl/lttng-tools)
* [lttngs-modules](https://github.com/sbu-fsl/lttng-modules)

As well as the following dependencies:
* userspace-rcu - a lockless synchronization method
* babeltrace - for trace format conversion
* trace2model - converts system call traces to DataSeries
* fsl-strace - an strace fork compatible with DataSeries
* [oneTBB](https://github.com/oneapi-src/oneTBB) - thread building blocks for parallel C++ programs
* libaio-dev
* libtool
* libboost-dev (v1.58 only)
* libboost-thread-dev (v1.58 only)
* libboost-program-options-dev (v1.58 only)
* build-essential
* libxml2-dev
* zlib1g-dev
* libdw-dev
* libelf-dev
* libgtk2.0-dev
* libnuma-dev
* libpopt-dev

## Setup

1. Ensure you have the FSL Linux kernel patch installed.
1. Install the following required programs and libraries:
    ```
    autoconf automake build-essential cmake g++ gcc git libaio-dev libboost-dev libboost-program-options-dev libboost-thread-dev libdw-dev libelf-dev libgtk2.0-dev libnuma-dev libpopt-dev libtool libxml2-dev libxml2-dev perl uuid-dev zlib1g-dev
    ```
    All of the above requirements are available through the APT package manager on Ubuntu 16.
1. Clone this repository
1. Run `build-fsl-lttng.sh`
    * Run with `--install` to install files and libraries under `usr/local/`
    * Run with `--install-packages` to install any missing packages
