#!/bin/bash -e

prefix_dir=$PWD/texlive-windows-arm64
workdir=$PWD
mkdir -p "$prefix_dir"
[ -z "$vcpkg_dir" ] && vcpkg_dir=$PWD/vcpkg
vcpkg_libs_dir=$vcpkg_dir/installed/arm64-mingw-dynamic
[ -z "$llvm_dir" ] && llvm_dir=$PWD/llvm-mingw

wget="wget -nc --progress=bar:force"
gitclone="git clone --depth=1 --recursive"

tlversion=20240311
tlcommithash=72e553ad9359226fae15e67b0af8632b2b0ba132

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
export LDFLAGS="-s -L$prefix_dir/lib -L$vcpkg_libs_dir/lib -Wl,--allow-multiple-definition"

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

mkdir -p src
mkdir -p $prefix_dir/lib/pkgconfig/ 
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


sed -i 's|\./himktables\$(EXEEXT)|himktables|' texk/web2c/Makefile.in 
mkdir build-woa
cd build-woa
../configure $commonflags --disable-native-texlive-build --disable-multiplatform --with-system-harfbuzz  --with-system-icu --with-system-graphite2 --with-system-cairo --with-system-pixman --with-system-gd --with-system-freetype2 --with-system-libpng  --with-system-zlib
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
make texlinks

# install mtxrun.dll (copy from MSYS2)
install -D -m755 "../texk/texlive/windows_mingw_wrapper/context/mtxrun.dll" \
    "$prefix_dir/bin/mtxrun.dll"

for _script in context contextjit luatools mtxrun mtxrunjit texexec texmfstart
do
install -D -m755 "../texk/texlive/windows_mingw_wrapper/context/mtxrun.exe" \
    "$prefix_dir/bin/${_script}.exe"
done

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
cd $workdir/upload/windows
cp euptex.exe uplatex.exe
cp euptex.exe uptex.exe
cp euptex.exe eptex.exe
cp euptex.exe platex.exe 
cp euptex.exe ptex.exe
cp epstopdf.exe repstopdf.exe
cp gbklatex.exe "bg5+latex.exe"
cp gbkpdflatex.exe "bg5+pdflatex.exe"
cp hitex.exe hilatex.exe
cp luatex.exe dvilualatex.exe
cp luatex.exe dviluatex.exe
cp luatex.exe luacsplain.exe
cp luahbtex.exe lualatex.exe
cp mpost.exe r-mpost.exe
cp pmpost.exe r-pmpost.exe
cp pdftex.exe amstex.exe
cp pdftex.exe csplain.exe
cp pdftex.exe eplain.exe
cp pdftex.exe etex.exe
cp pdftex.exe jadetex.exe
cp pdftex.exe latex.exe
cp pdftex.exe mex.exe
cp pdftex.exe mllatex.exe
cp pdftex.exe mltex.exe
cp pdftex.exe pdfetex.exe
cp pdftex.exe pdfcsplain.exe
cp pdftex.exe pdfjadetex.exe
cp pdftex.exe pdflatex.exe
cp pdftex.exe pdfmex.exe
cp pdftex.exe pdfxmltex.exe
cp pdftex.exe texsis.exe
cp pdftex.exe utf8mex.exe
cp pdftex.exe xmltex.exe
cp tex.exe lollipop.exe
cp xetex.exe xelatex.exe
cp xdvipdfmx.exe ebb.exe
cp upbibtex.exe pbibtex.exe
cp updvitype.exe pdvitype.exe
cp uptftopl.exe ptftopl.exe
cp uppltotf.exe ppltotf.exe
cp upmpost.exe r-upmpost.exe