#!/bin/bash
#
# Description: Install script for fsl-lttng and dependencies
# Authors:     Thomas Fleming, Lukas Velikov

####################
# Script variables #
####################
readonly programDependencies=("asciidoc" "autoconf" "bison" "flex" "g++" "gcc" "git" "libdw-dev" "libelf-dev" "libgtk2.0-dev" "libpopt-dev" "libnuma-dev" "libtool" "libxml2-dev" "make" "perl" "uuid-dev")
readonly numberOfCores="$(nproc --all)"
configArgs=""
install=false
installDir="$(pwd)/fsl-lttng"
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
    --install              Install libraries and binaries under /usr/local
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
        --install)
            install=true
            installDir="/usr/local"
            shift # past argument
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
if [[ "${install}" == true ]]; then
    if ! command -v sudo &>/dev/null; then
        echo "Script could not find 'sudo' command. Cannot install." >&2
        exit 1
    fi
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
[[ -d "userspace-rcu" ]] || runcmd git clone https://github.com/sbu-fsl/userspace-rcu.git
[[ -d "lttng-ust" ]] || runcmd git clone https://github.com/sbu-fsl/lttng-ust.git
[[ -d "lttng-tools" ]] || runcmd git clone https://github.com/sbu-fsl/lttng-tools.git
[[ -d "lttng-modules" ]] || runcmd git clone https://github.com/sbu-fsl/lttng-modules.git
[[ -d "babeltrace" ]] || runcmd git clone https://github.com/sbu-fsl/babeltrace.git
[[ -d "trace2model" ]] || runcmd git clone https://github.com/sbu-fsl/trace2model.git
[[ -d "fsl-strace" ]] || runcmd git clone https://github.com/sbu-fsl/fsl-strace.git

# Install userspace-rcu
runcmd cd userspace-rcu
runcmd ./bootstrap
runcmd ./configure "${configArgs}"
runcmd make -j"${numberOfCores}" 
runcmd sudo make -j"${numberOfCores}" install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Install lttng-ust
runcmd cd  lttng-ust
runcmd ./bootstrap
runcmd ./configure "${configArgs}"
runcmd make -j"${numberOfCores}" 
runcmd sudo make -j"${numberOfCores}" install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Install lttng-tools
runcmd cd lttng-tools
runcmd git checkout ds
runcmd ./bootstrap
runcmd ./configure "${configArgs}"
rumcmd make -j"${numberOfCores}" 
runcmd sudo make -j"${numberOfCores}" install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Install lttng-modules
# Exhausts memory at 1 GiB memory, so try to have more
# Requires fsl-lttng-linux kernel
runcmd cd lttng-modules
runcmd git checkout ds
runcmd make -j"${numberOfCores}" 
runcmd sudo make -j"${numberOfCores}" modules_install
runcmd sudo depmod -a
runcmd cd "${repositoryDir}"

# Install babeltrace
runcmd cd babeltrace
runcmd git checkout master  # Default branch depends on strace2ds
runcmd ./bootstrap
runcmd ./configure "${configArgs}"
runcmd make -j"${numberOfCores}" 
runcmd sudo make install -j"${numberOfCores}" 
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Install fsl-strace
runcmd cd fsl-strace
runcmd sudo chmod +x build-fsl-strace.sh
runcmd sudo ./build-fsl-strace.sh --install --install-packages
runcmd cd "${repositoryDir}"
