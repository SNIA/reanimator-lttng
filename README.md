# FSL LTTng

fsl lttng orchestrator

## Setup

1. Ensure you have the FSL Linux kernel patch installed (TODO: figure out what the "FSL Linux kernel patch" is actually called and provide a link to it, if possible)
1. Install the following required programs and libraries:
    ```
    autoconf automake build-essential cmake g++ gcc git libaio-dev libboost-dev libboost-program-options-dev libboost-thread-dev libdw-dev libelf-dev libgtk2.0-dev libnuma-dev libpopt-dev libtool libxml2-dev libxml2-dev perl uuid-dev zlib1g-dev
    ```
    All of the above requirements are available through the APT package manager on Ubuntu 16. 
1. Clone this repository
1. Run `build-fsl-lttng.sh`
    * Run with `--install` to install files and libraries under `usr/local/`
    * Run with `--install-packages` to install any missing packages

