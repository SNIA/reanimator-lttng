#!/bin/bash
#
# Install script for fsl-lttng and dependencies

####################
# Script variables #
####################
# TODO: See if numberOfCores is necessary
# TODO: See if appending configArgs is necessary
# readonly numberOfCores="$(nproc --all)"
# configArgs=""
readonly dependencies=("autoconf" "libtool" "make" "gcc" "g++" "perl" "git" "flex" "bison" "asciidoc" "libpopt-dev" "libxml2-dev" "uuid-dev" "libgtk2.0-dev" "libelf-dev" "libdw-dev")
install=false
installPackages=false
installDir="$(pwd)/fsl-lttng"
repositoryDir="$(pwd)/build"

####################
# Script functions #
####################
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

function printUsage
{
    (
    cat << EOF
Usage: $0 [options...]
Options:
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
if [[ "${install}" = true ]]; then
    if ! command -v sudo &>/dev/null; then
        echo "Script could not find 'sudo' command. Cannot install." >&2
        exit 1
    fi
fi

# Check whether program dependencies are installed
for program in "${dependencies[@]}"; do
    programPath=$(command -v "${program}")
    if [[ $? == 0 ]]; then
        echo "${program}: Located at ${programPath}"
    elif [[ "${installPackages}" == true ]]; then
        echo "${program}: Not found. Installing..."
        runcmd sudo apt-get install -y "${program}"
    else
        echo "${program}: Not found."
        missingPrograms+=("${program}")
    fi
done

# Clone repositories
# TODO: Change SSH git clone to HTTPS
runcmd mkdir -p "${repositoryDir}"
runcmd cd "${repositoryDir}"
[[ -d "userspace-rcu" ]] || runcmd git clone git@github.com:sbu-fsl/userspace-rcu.git
[[ -d "lttng-ust" ]] || runcmd git clone git@github.com:sbu-fsl/lttng-ust.git
[[ -d "lttng-tools" ]] || runcmd git clone git@github.com:sbu-fsl/lttng-tools.git
[[ -d "lttng-modules" ]] || runcmd git clone git@github.com:sbu-fsl/lttng-modules.git
[[ -d "babeltrace" ]] || runcmd git clone git@github.com:sbu-fsl/babeltrace.git
[[ -d "trace2model" ]] || runcmd git clone git@github.com:sbu-fsl/trace2model.git
[[ -d "fsl-strace" ]] || runcmd git clone git@github.com:sbu-fsl/fsl-strace.git
# Commented out for now, since we're putting this script in fsl-lttng
# [[ -d "fsl-lttng" ]] || runcmd git clone git@github.com:sbu-fsl/fsl-lttng.git


# Install userspace-rcu
runcmd cd userspace-rcu
runcmd ./bootstrap
runcmd ./configure
runcmd make
runcmd sudo make install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Install lttng-ust
runcmd cd  lttng-ust
runcmd ./bootstrap
runcmd ./configure
runcmd make
runcmd sudo make install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Install lttng-tools
runcmd cd lttng-tools
runcmd ./bootstrap
runcmd ./configure
rumcmd make
runcmd sudo make install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Install lttng-modules
# Exhausts memory at 1 GiB memory, so try to have more
# Requires fsl-lttng-linux kernel
runcmd cd lttng-modules
runcmd make
runcmd sudo make modules_install
runcmd sudo depmod -a
runcmd cd "${repositoryDir}"

# Install babeltrace
runcmd cd babeltrace
runcmd git checkout master  # Default branch depends on strace2ds
runcmd ./bootstrap
runcmd ./configure
runcmd make
runcmd sudo make install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Install fsl-strace
runcmd cd fsl-strace
runcmd git checkout buildall_script  # TODO: Remove when buildall script gets merged into master
runcmd sudo chmod +x dist/build-syscall-replayer.sh
runcmd sudo dist/build-syscall-replayer.sh
runcmd cd "${repositoryDir}"
