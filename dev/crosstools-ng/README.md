# crosstools-ng usage

## Procedure

### Related Directories

`scripts/setenv.sh` sets up environment variables as expected in this description.
If diverting, please change `scripts/setenv.sh` and throughout your build procedure.

| Variable                   | Path                                                   |
| -------------------------- | ------------------------------------------------------ |
| `PATH`                     | `/usr/local/bin:${PATH}`                               |
| `CT_PREFIX`                | `${HOME}/crosstool-ng`                                 |
| `CT_LOCAL_TARBALLS_DIR`    | `${CT_PREFIX}/src`                                     |

`scripts/setenv.sh` also creates `CT_LOCAL_TARBALLS_DIR`, if not existing.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~{.sh}
mkdir -p ${CT_LOCAL_TARBALLS_DIR}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Environment Variable Setup
Setting up directories as described above

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~{.sh}
. ./scripts/setenv.sh
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Install crosstools-ng
I have used [crosstools-ng](https://crosstool-ng.github.io/) version 1.29.0,
build from its [git repo](https://github.com/crosstool-ng/crosstool-ng) as follows.

To install the Debian/Ubuntu prerequisites as described below,
you may also use [scripts/install-prerequisites.sh](scripts/install-prerequisites.sh).

Install `crosstool-ng` under `/usr/local`.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~{.sh}
# Debian or Ubuntu
sudo apt-get install git build-essential autotools-dev automake autoconf g++ gcc libc-dev libpthread-stubs0-dev \
                     cmake cmake-extras extra-cmake-modules ccache \
                     texinfo gawk libtool-bin flex bison libncurses-dev \
                     lzip curl meson ninja-build device-tree-compiler \
                     help2man python3-dev

git clone https://github.com/crosstool-ng/crosstool-ng
cd crosstool-ng
git checkout -b b_1.28.0 crosstool-ng-1.28.0
git clean -d -f -x
./bootstrap

./configure --prefix=/usr/local
make
sudo make install
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Toolchain build w/ crosstools-ng
Note: Each of the used scripts below source (read and evaluate)
the `scripts/setenv.sh` to setup required environment variables
as described above.

#### `x86_64-debian13-linux-gnu16`
A gcc 16.2 build for C++26 support on Debian 13.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~{.sh}
mkdir x86_64-debian13-linux-gnu16
cp x86_64-debian13-linux-gnu16.config x86_64-debian13-linux-gnu16/.config
ct-ng upgradeconfig
ct-ng build
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

