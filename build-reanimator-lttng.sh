#!/bin/bash
#
# Description: Install script for reanimator-lttng and dependencies
# Authors:     Thomas Fleming, Lukas Velikov

####################
# Script variables #
####################

readonly programDependencies=("asciidoc" "autoconf" "automake" "bison" "cmake" "flex" "git" "make" "perl")
readonly numberOfCores="$(nproc --all)"
configArgs=""
install=false
installDir="/usr/local"
installPackages=false
missingPrograms=()
repositoryDir="$(pwd)/build"

####################
# Script functions #
####################

# Wrapper function for running commands with feedback
function runcmd
{
    echo "CMD: $*"
    sleep 0.2
    "$@"
    ret=$?
    if test $ret -ne 0 ; then
        exit $ret
    fi
}

# Output usage string (invoked on -h or --help)
function printUsage
{
    (
    cat << EOF
Usage: $0 [options...]
Options:
    --config-args ARGS     Append ARGS to every ./configure command
    --install-packages     Automatically use apt-get to install missing packages
    -h, --help             Print this help message
EOF
    ) >&2
    exit 0
}

##################
# Script startup #
##################

# Parse script arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case "${key}" in
        --config-args)
            shift # past argument
            "${configArgs}"="$1"
            shift # past value
            ;;
        --install-packages)
            if command -v apt-get >/dev/null; then
                installPackages=true
            else
                echo "Could not find apt-get. Missing packages must be \
                installed manually." >&2
            fi
            shift # past argument
            ;;
        -h|--help)
            printUsage
            shift # past argument
            ;;
        *)
            shift # past argument
            ;;
    esac
done

# See if sudo is installed
if ! command -v sudo &>/dev/null; then
    echo "Script could not find 'sudo' command. Cannot install." >&2
    exit 1
fi

# Check whether program dependencies are installed
for program in "${programDependencies[@]}"; do
    programPath=$(command -v "${program}")
    if [[ $? == 0 ]]; then
        echo "${program}: Located at ${programPath}"
    elif [[ "${installPackages}" == true ]]; then
        echo "${program}: Not found. Queuing for installation..."
        missingPrograms+=("${program}")
    else
        echo "${program}: Not found."
        missingPrograms+=("${program}")
    fi
done

# Check whether the user has all required programs for building
if [[ "${#missingPrograms[@]}" -gt 0 ]]; then
    if [[ "${installPackages}" == true ]]; then
        echo "Installing missing programs."
        runcmd sudo apt-get install -y "${missingPrograms[@]}"
    else
        echo "Could not find all required programs. Not found:"
        for program in "${missingPrograms[@]}"; do
            echo "  ${program}"
        done

        echo "To install on a Debian-based system, run the command"
        echo "  sudo apt-get install ${missingPrograms[*]}"
        exit 1
    fi
fi

# Clone repositories
runcmd mkdir -p "${repositoryDir}"
runcmd cd "${repositoryDir}"
[[ -d "reanimator-userspace-rcu" ]] || runcmd git clone https://github.com/SNIA/reanimator-userspace-rcu.git
[[ -d "reanimator-lttng-ust" ]] || runcmd git clone https://github.com/SNIA/reanimator-lttng-ust.git
[[ -d "reanimator-lttng-tools" ]] || runcmd git clone https://github.com/SNIA/reanimator-lttng-tools.git
[[ -d "reanimator-lttng-modules" ]] || runcmd git clone https://github.com/SNIA/reanimator-lttng-modules.git
[[ -d "reanimator-babeltrace" ]] || runcmd git clone https://github.com/SNIA/reanimator-babeltrace.git
[[ -d "reanimator-library" ]] || runcmd git clone https://github.com/SNIA/reanimator-library.git
[[ -d "reanimator-replayer" ]] || runcmd git clone https://github.com/SNIA/reanimator-replayer.git
[[ -d "oneTBB" ]] || runcmd git clone https://github.com/oneapi-src/oneTBB.git

# Build reanimator-userspace-rcu
runcmd cd reanimator-userspace-rcu
runcmd ./bootstrap
runcmd ./configure "${configArgs}"
runcmd make -j"${numberOfCores}"
runcmd sudo make -j"${numberOfCores}" install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Build reanimator-lttng-ust
runcmd cd reanimator-lttng-ust
runcmd ./bootstrap
runcmd ./configure "${configArgs}"
runcmd make -j"${numberOfCores}"
runcmd sudo make -j"${numberOfCores}" install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Build reanimator-lttng-tools
runcmd cd reanimator-lttng-tools
runcmd git checkout ds
runcmd ./bootstrap
runcmd ./configure "${configArgs}"
rumcmd make -j"${numberOfCores}"
runcmd sudo make -j"${numberOfCores}" install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Build reanimator-lttng-modules
# Exhausts memory at 1 GiB memory, so try to have more
# Requires Reanimator fsl-lttng-linux kernel
runcmd cd reanimator-lttng-modules
ubuntu_version=$(lsb_release -d | awk '{print $3}')
echo $ubuntu_version
if [[ "${ubuntu_version}" == "18.04.3" ]]; then
    runcmd git checkout u18-changes  # u18 support
else
    runcmd git checkout ds
fi
runcmd make -j"${numberOfCores}"
runcmd sudo make -j"${numberOfCores}" modules_install
runcmd sudo depmod -a
runcmd cd "${repositoryDir}"

# Build reanimator-library
runcmd cd reanimator-library
runcmd chmod +x build-reanimator-library.sh
runcmd ./build-reanimator-library.sh --install
runcmd cd "${repositoryDir}"

# Build TBB
runcmd cd oneTBB
runcmd git fetch --all --tags --prune
runcmd git checkout tags/v2020.3
runcmd sudo cp -r ./include/. "${installDir}/include"
runcmd sudo make tbb_build_dir="${installDir}/lib" tbb_build_prefix=one_tbb -j"${numberOfCores}"
runcmd sudo cp /usr/local/lib/one_tbb_release/*.so* /usr/local/lib
runcmd cd "${repositoryDir}"

# Build reanimator-replayer
runcmd cd reanimator-replayer
runcmd rm -rf build
runcmd mkdir build
runcmd cd build
runcmd cmake ..
runcmd make -j"${numberOfCores}"
runcmd cd "${repositoryDir}"

# Build reanimator-babeltrace
runcmd cd reanimator-babeltrace
runcmd git checkout ds
runcmd ./bootstrap
runcmd sed -i 's/O2/O0/g' configure  # U18 O2 Hotfix
runcmd ./configure "${configArgs}"
runcmd make -j"${numberOfCores}"
runcmd sudo make -j"${numberOfCores}" install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Build reanimator-lttng
runcmd sudo mkdir -p /usr/local/strace2ds/tables/
runcmd sudo cp "${repositoryDir}"/../syscalls_name_number.table /usr/local/strace2ds/tables/
runcmd cd "${repositoryDir}"
runcmd cmake ..
runcmd make -j"${numberOfCores}"
