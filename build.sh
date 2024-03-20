#!/bin/bash
set -e

ARCH=aarch64
VER=python3.11

jobs=32
install_dir=/opt/${VER}
toolchain=${ARCH}-linux-musl

echo "Creating ${install_dir} folder with $(whoami) user permissions ..."
[ -d ${install_dir} ] || mkdir -p ${install_dir}
[ -d build ] || mkdir build
cd build

for d in $(ls ../apk/*)
do
echo $d
dir=$(basename $d)
dir=${dir%%.*}

if ! [ -d ${dir}* ]; then
tar xf $d

# To build
if [[ $dir == Python-3* ]]; then
continue

elif [[ $dir == zlib* ]]; then
pushd ${dir}*
CROSS_PREFIX="${toolchain}-"  ./configure --prefix=${install_dir}
make -j${jobs} && make install
popd

else
pushd ${dir}*
./configure --host=${toolchain} --enable-static=yes --prefix=${install_dir} 
make -j${jobs} && make install
popd

fi
fi
done

echo "Building ${VER}"
cd Python-3*

export PKG_CONFIG_PATH=${install_dir}/lib/pkgconfig

unset CFLAGS LDFLAGS
export CFLAGS+=" -I${install_dir}/include/" # Just to include libffi
# export LDFLAGS+=" -L${install_dir}/lib/"

echo '
ac_cv_file__dev_ptmx=yes
ac_cv_file__dev_ptc=no
' > ./CONFIG_SITE

./configure --prefix=${install_dir} --with-build-python=${VER} --build=x86_64 --host=${toolchain} \
--enable-ipv6 CONFIG_SITE=./CONFIG_SITE --enable-optimizations

# --with-static-libpython=yes
# --enable-shared=no
# --with-system-ffi=no

make -j8 && make install 
# make test

echo ========= Cross compiled python successfully =========
echo Please check ${install_dir}