#!/bin/bash -e

prefix_dir=$PWD/texlive-windows-arm64
workdir=$PWD
mkdir -p "$prefix_dir/bin"
[ -z "$vcpkg_dir" ] && vcpkg_dir=$PWD/vcpkg
vcpkg_libs_dir=$vcpkg_dir/installed/arm64-mingw-dynamic
[ -z "$llvm_dir" ] && llvm_dir=$PWD/llvm-mingw

wget="wget -nc --progress=bar:force"
gitclone="git clone --depth=1 --recursive"

tlversion=20240311
tlcommithash=252b7348a26bbd8c29c7e379017863cffc3a8a14
# asymptote_ver=3.02git

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
export CPPFLAGS="-I$prefix_dir/include -I$vcpkg_libs_dir/include -Wno-error=incompatible-function-pointer-types"
export LDFLAGS="-s -L$prefix_dir/lib -L$vcpkg_libs_dir/lib" # -Wl,--allow-multiple-definition"

# anything that uses pkg-config
export PKG_CONFIG=/usr/bin/pkg-config
export PKG_CONFIG_LIBDIR="$prefix_dir/lib/pkgconfig:$vcpkg_libs_dir/lib/pkgconfig"
export PKG_CONFIG_PATH=$PKG_CONFIG_LIBDIR

# autotools(-like)
commonflags="--prefix=$prefix_dir --build=x86_64-linux-gnu --host=$TARGET --enable-static=no --enable-shared --disable-debug"

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
    make -j $(nproc)
    make install
}

function buildcallexe {
    $TARGET-gcc -Os -s -DEXEPROG=\"$1.exe\" -o "$2.exe" callexe.c
    rm -rf "$prefix_dir/bin/$2.exe"
    install -D -m755 "$2.exe" "$prefix_dir/bin/$2.exe"
}

function buildcallscripts {
    $TARGET-g++ -Os -s -DSCRIPTLINK=\"$2\" -DINTERPRETER=\"$3\" -o "$1.exe" callscripts.cpp
    rm -rf "$prefix_dir/bin/$1.exe"
    install -D -m755 "$1.exe" "$prefix_dir/bin/$1.exe"
}

function tlmklinks {
    cd ../texk/texlive/windows_mingw_wrapper
    buildcallexe euptex uplatex
    buildcallexe euptex uptex
    buildcallexe euptex eptex
    buildcallexe euptex platex 
    buildcallexe euptex ptex
    buildcallexe epstopdf repstopdf
    buildcallexe gbklatex "bg5+latex"
    buildcallexe gbkpdflatex "bg5+pdflatex"
    buildcallexe hitex hilatex
    buildcallexe luatex dvilualatex
    buildcallexe luatex dviluatex
    buildcallexe luatex luacsplain
    buildcallexe luahbtex lualatex
    buildcallexe mpost r-mpost
    buildcallexe pmpost r-pmpost
    buildcallexe pdftex amstex
    buildcallexe pdftex csplain
    buildcallexe pdftex eplain
    buildcallexe pdftex etex
    buildcallexe pdftex jadetex
    buildcallexe pdftex latex
    buildcallexe pdftex mex
    buildcallexe pdftex mllatex
    buildcallexe pdftex mltex
    buildcallexe pdftex pdfetex
    buildcallexe pdftex pdfcsplain
    buildcallexe pdftex pdfjadetex
    buildcallexe pdftex pdflatex
    buildcallexe pdftex pdfmex
    buildcallexe pdftex pdfxmltex
    buildcallexe pdftex texsis
    buildcallexe pdftex utf8mex
    buildcallexe pdftex xmltex
    buildcallexe tex lollipop
    buildcallexe xetex xelatex
    buildcallexe xdvipdfmx ebb
    buildcallexe upbibtex pbibtex
    buildcallexe updvitype pdvitype
    buildcallexe uptftopl ptftopl
    buildcallexe uppltotf ppltotf
    buildcallexe upmpost r-upmpost
    cd $workdir/wrappers
    buildcallscripts latexmk ../../texmf-dist/scripts/latexmk/latexmk.pl
    buildcallscripts epstopdf ../../texmf-dist/scripts/epstopdf/epstopdf.pl
}

mkdir -p src
cd src

# texlive
usetlsrctarball=0
if [[ $usetlsrctarball -eq 1 ]]
then
    [ -d texlive-$tlversion-source ] || $wget https://mirrors.ctan.org/systems/texlive/Source/texlive-$tlversion-source.tar.xz
    tar xf texlive-$tlversion-source.tar.xz
    cd texlive-$tlversion-source
else
    [ -d texlive-source ] || git clone https://github.com/TeX-Live/texlive-source
    cd texlive-source
    git checkout $tlcommithash
fi


sed -i 's|\./himktables\$(EXEEXT)|#\./himktables\$(EXEEXT)|' texk/web2c/Makefile.in 
mkdir build-woa
cd build-woa
mkdir -p texk/web2c
cp ../texk/web2c/hitexdir/hitables.c texk/web2c
../configure $commonflags --disable-native-texlive-build --disable-cxx-runtime-hack --disable-multiplatform --with-system-harfbuzz --with-system-icu --with-system-graphite2 --with-system-cairo --with-system-pixman --with-system-gd --with-system-freetype2 --with-system-libpng  --with-system-zlib --enable-xindy --disable-xindy-docs --disable-xindy-rules --enable-tex-synctex --enable-mflua-nowin --enable-mfluajit-nowin
make -j $(nproc)

# build launchers (copy from MSYS2)
cp "libs/lua53/.libs/texlua.dll" ../texk/texlive/windows_mingw_wrapper
cp "libs/lua53/.libs/libtexlua53.dll.a" ../texk/texlive/windows_mingw_wrapper
pushd ../texk/texlive/windows_mingw_wrapper

echo '1 ICON "tlmgr.ico"'>texlive.rc
$TARGET-windres texlive.rc texlive.o

$TARGET-gcc -Os -s -shared -Wl,--out-implib=librunscript.dll.a -o runscript.dll runscript_dll.c -L./ -ltexlua53
$TARGET-gcc -Os -s -o runscript.exe runscript_exe.c texlive.o -L./ -lrunscript
$TARGET-gcc -mwindows -Os -s -o wrunscript.exe wrunscript_exe.c texlive.o -L./ -lrunscript

cd context
$TARGET-gcc -Os -s -shared -Wl,--out-implib=libmtxrun.dll.a -o mtxrun.dll mtxrun_dll.c
$TARGET-gcc -Os -s -o mtxrun.exe mtxrun_exe.c -L./ -lmtxrun

popd

# install
make install

# asymptote
pushd ../utils/asymptote
sed -i 's|_MSC_VER|_WIN32|' psfile.cc 
sed -i 's|_MSC_VER|_WIN32|' settings.h
./autogen.sh
cd gc
./configure --build=x86_64-linux-gnu --host=$TARGET --enable-static --enable-shared=no --enable-cplusplus --enable-throw-bad-alloc-library
make -j $(nproc) 
cd ..
LDFLAGS="$LDFLAGS gc/.libs/libgccpp.a -lshlwapi -lole32" ./configure --build=x86_64-linux-gnu --host=$TARGET --enable-texlive-build 
sed -i 's|-std=c++17| |' Makefile 
ln $llvm_dir/generic-w64-mingw32/include/winsock2.h $llvm_dir/generic-w64-mingw32/include/Winsock2.h
ln $llvm_dir/generic-w64-mingw32/include/windows.h $llvm_dir/generic-w64-mingw32/include/Windows.h
ln $llvm_dir/generic-w64-mingw32/include/shlwapi.h $llvm_dir/generic-w64-mingw32/include/Shlwapi.h
ln $llvm_dir/generic-w64-mingw32/include/shellapi.h $llvm_dir/generic-w64-mingw32/include/Shellapi.h
make -j $(nproc) 
cp asy.exe $prefix_dir/bin 
popd

# install mtxrun.dll (copy from MSYS2)
install -D -m755 "../texk/texlive/windows_mingw_wrapper/context/mtxrun.dll" \
    "$prefix_dir/bin/mtxrun.dll"

for _script in context contextjit luatools mtxrun mtxrunjit texexec texmfstart
do
install -D -m755 "../texk/texlive/windows_mingw_wrapper/context/mtxrun.exe" \
    "$prefix_dir/bin/${_script}.exe"
done

# make links
tlmklinks

# package
cd $prefix_dir
mkdir -p $workdir/upload/windows
mkdir -p $workdir/upload/vcpkg-dll
cp -r ./bin/* $workdir/upload/windows/
cp $llvm_dir/aarch64-w64-mingw32/bin/libc++.dll $workdir/upload/windows/
cp $llvm_dir/aarch64-w64-mingw32/bin/libunwind.dll $workdir/upload/windows/
cp -r $vcpkg_libs_dir/bin/*.dll $workdir/upload/vcpkg-dll
$TARGET-strip $workdir/upload/windows/*.exe
$TARGET-strip $workdir/upload/windows/*.dll
$TARGET-strip $workdir/upload/vcpkg-dll/*.dll