#!/bin/bash
#
# Description: Install script for fsl-lttng and dependencies
# Authors:     Thomas Fleming, Lukas Velikov

####################
# Script variables #
####################

readonly programDependencies=("asciidoc" "bison" "flex" "make")
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
[[ -d "trace2model" ]] || runcmd git clone https://github.com/sbu-fsl/trace2model.git
[[ -d "oneTBB" ]] || runcmd git clone https://github.com/oneapi-src/oneTBB.git

# Build userspace-rcu
runcmd cd userspace-rcu
runcmd ./bootstrap
runcmd ./configure "${configArgs}"
runcmd make -j"${numberOfCores}"
runcmd sudo make -j"${numberOfCores}" install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Build lttng-ust
runcmd cd  lttng-ust
runcmd ./bootstrap
runcmd ./configure "${configArgs}"
runcmd make -j"${numberOfCores}"
runcmd sudo make -j"${numberOfCores}" install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Build lttng-tools
runcmd cd lttng-tools
runcmd git checkout ds
runcmd ./bootstrap
runcmd ./configure "${configArgs}"
rumcmd make -j"${numberOfCores}"
runcmd sudo make -j"${numberOfCores}" install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Build lttng-modules
# Exhausts memory at 1 GiB memory, so try to have more
# Requires fsl-lttng-linux kernel
runcmd cd lttng-modules
ubuntu_version=$(lsb_release -d | awk '{print $3}')
echo $ubuntu_version
if [[ "${ubuntu_version}" == "18.04.3" ]]; then
    runcmd git checkout u18-changes
else
    runcmd git checkout ds
fi
runcmd make -j"${numberOfCores}"
runcmd sudo make -j"${numberOfCores}" modules_install
runcmd sudo depmod -a
runcmd cd "${repositoryDir}"

# Build fsl-strace
runcmd cd fsl-strace
runcmd git checkout ds
runcmd sudo chmod +x build-fsl-strace.sh
runcmd sudo ./build-fsl-strace.sh --install --install-packages
runcmd cd "${repositoryDir}"

# Build TBB
runcmd cd oneTBB
if [[ "${install}" == true ]]; then
    runcmd sudo cp -r ./include/. "${installDir}/include"
    runcmd sudo make tbb_build_dir="${installDir}/lib" \
        tbb_build_prefix=one_tbb -j"${numberOfCores}"
else
    runcmd cp -r ./include/. "${installDir}/include"
    runcmd make tbb_build_dir="${installDir}/lib" tbb_build_prefix=one_tbb \
        -j"${numberOfCores}"
fi
runcmd sudo cp /usr/local/lib/one_tbb_release/*.so* /usr/local/lib
runcmd cd "${repositoryDir}"

# Build trace2model
runcmd cd trace2model/strace2ds-library
runcmd autoreconf -v -i
runcmd rm -rf BUILD
runcmd mkdir -p BUILD
runcmd mkdir -p xml
runcmd cd tables
runcmd perl gen-xml-enums.pl
runcmd cd ../
runcmd cp -r ./xml BUILD
runcmd cd BUILD
runcmd export CXXFLAGS="-I${installDir}/include"
runcmd export LDFLAGS="-L${installDir}/lib"
runcmd ../configure --enable-shared --disable-static \
    --prefix="${installDir}/strace2ds"
runcmd make clean
runcmd make -j"${numberOfCores}"
if [[ "${install}" == true ]]; then
    runcmd sudo make -j"${numberOfCores}" install
else
    runcmd make -j"${numberOfCores}" install
fi
runcmd cd "${repositoryDir}"

# Build syscall-replayer
runcmd cd trace2model/syscall-replayer
runcmd make -j"${numberOfCores}"
runcmd cd "${repositoryDir}"

# Build babeltrace
runcmd cd babeltrace
runcmd git checkout ds
runcmd ./bootstrap
runcmd sed -i 's/O2/O0/g' configure  # U18 O2 Hotfix
runcmd ./configure "${configArgs}"
runcmd make -j"${numberOfCores}"
runcmd sudo make -j"${numberOfCores}" install
runcmd sudo ldconfig
runcmd cd "${repositoryDir}"

# Build FSL-LTTng
runcmd sudo cp "${repositoryDir}"/../syscalls_name_number.table /usr/local/strace2ds/tables/
runcmd cd "${repositoryDir}"
runcmd cmake ..
runcmd make -j"${numberOfCores}"
