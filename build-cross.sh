#!/bin/bash -e

prefix_dir=$PWD/texlive-depends
mkdir -p "$prefix_dir"
[ -z "$vcpkg_dir" ] && vcpkg_dir=$PWD/vcpkg
vcpkg_libs_dir=$vcpkg_dir/installed/arm64-mingw-dynamic
[ -z "$llvm_dir" ] && llvm_dir=$PWD/llvm-mingw

wget="wget -nc --progress=bar:force"
gitclone="git clone --depth=1 --recursive"

tlversion=20240311

export PATH=$llvm_dir/bin:$PATH
export TARGET=aarch64-w64-mingw32
export CC=$TARGET-gcc
export CXX=$TARGET-g++
export AR=$TARGET-ar
export NM=$TARGET-nm
export RANLIB=$TARGET-ranlib
export STRIP=$TARGET-strip

export CFLAGS="-O2 -I$prefix_dir/include -I$vcpkg_libs_dir/include"
export CXXFLAGS=$CFLAGS
export CPPFLAGS="-I$prefix_dir/include -I$vcpkg_libs_dir/include"
export LDFLAGS="-s -L$prefix_dir/lib -L$vcpkg_libs_dir/lib"

# anything that uses pkg-config
export PKG_CONFIG=/usr/bin/pkg-config
export PKG_CONFIG_LIBDIR="$prefix_dir/lib/pkgconfig:$vcpkg_libs_dir/lib/pkgconfig"
export PKG_CONFIG_PATH=$PKG_CONFIG_LIBDIR

# autotools(-like)
commonflags="--prefix=$prefix_dir --build=aarch64-linux-gnu --host=$TARGET --enable-static=no --enable-shared --disable-debug"

# CMake
cmake_args=(
    -G "Ninja" -B "build"
    -Wno-dev
    -DCMAKE_SYSTEM_NAME=Windows
    -DCMAKE_FIND_ROOT_PATH="$prefix_dir;$vcpkg_libs_dir"
    -DCMAKE_RC_COMPILER="${TARGET}-windres"
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=$prefix_dir
)

function cmakeplusinstall {
    cmake --build build
    cmake --install build
}

function gnumakeplusinstall {
    make -j $(nproc) || true
    make install || true
}

mkdir -p src
mkdir -p $prefix_dir/lib/pkgconfig/ 
cd src

# texlive
[ -d texlive-$tlversion-source ] || $wget https://mirrors.ctan.org/systems/texlive/Source/texlive-$tlversion-source.tar.xz
tar xf texlive-$tlversion-source.tar.xz
cd texlive-$tlversion-source
mkdir build-woa
cd build-woa
../configure $commonflags --disable-native-texlive-build --disable-multiplatform --with-system-harfbuzz  --with-system-icu  --with-system-zziplib --with-system-graphite2 --with-system-cairo --with-system-pixman --with-system-gd --with-system-freetype2 --with-system-libpng  --with-system-zlib --disable-luajittex --disable-luajithbtex --disable-mfluajit
gnumakeplusinstall