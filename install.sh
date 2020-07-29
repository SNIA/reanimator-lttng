# Install script for fsl-lttng dependencies
# TODO: Provide option to install into /usr/local vs local directory

readonly dependencies=("autoconf" "libtool" "make" "gcc" "g++" "perl" "git" "flex" "bison" "asciidoc" "libpopt-dev" "libxml2-dev" "uuid-dev" "libgtk2.0-dev" "libelf-dev" "libdw-dev")
# TODO: Decide if these switches are necessary
install=true
installPackages=true

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

# Install userspace-rcu
# TODO: Change SSH git clone to HTTPS
runcmd git clone git@github.com:sbu-fsl/userspace-rcu.git
runcmd cd userspace-rcu
runcmd ./bootstrap
runcmd ./configure
runcmd make
runcmd sudo make install
runcmd sudo ldconfig
runcmd cd ..

# Install lttng-ust
runcmd git clone git@github.com:sbu-fsl/lttng-ust.git
runcmd cd  lttng-ust
runcmd ./bootstrap
runcmd ./configure
runcmd make
runcmd sudo make install
runcmd sudo ldconfig
runcmd cd ..

# Install lttng-tools
runcmd git clone git@github.com:sbu-fsl/lttng-tools.git
runcmd cd lttng-tools
runcmd ./bootstrap
runcmd ./configure
rumcmd make
runcmd sudo make install
runcmd sudo ldconfig
runcmd cd ..

# Install lttng-modules
# Exhausts memory at 1 GiB memory, so try to have more
# Requires fsl-lttng-linux kernel
runcmd git clone git@github.com:sbu-fsl/lttng-modules.git
runcmd cd lttng-modules
runcmd make
runcmd sudo make modules_install
runcmd sudo depmod -a
runcmd cd ..

# Install babeltrace
runcmd git clone git@github.com:sbu-fsl/babeltrace.git
runcmd cd babeltrace
runcmd git checkout master  # Default branch depends on strace2ds
runcmd ./bootstrap
runcmd ./configure
runcmd make
runcmd sudo make install
runcmd sudo ldconfig
runcmd cd ..

# Install trace2model
runcmd git clone git@github.com:sbu-fsl/trace2model.git

# Install fsl-strace
runcmd git clone git@github.com:sbu-fsl/fsl-strace.git
runcmd cd fsl-strace
runcmd git checkout buildall_script  # TODO: Remove when buildall script gets merged int master
runcmd sudo chmod +x dist/build-syscall-replayer.sh
runcmd sudo dist/build-syscall-replayer.sh

# Add fsl-lttng
# Commented out for now, since we're putting this script in fsl-lttng
# runcmd git clone git@github.com:sbu-fsl/fsl-lttng.git
