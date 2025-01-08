#!/bin/bash

set -e
runtime=clang-aarch64
# runtime=clang-x86_64
wget="wget -nc --progress=bar:force"
workdir=$(pwd)
tlversion=20240311

do_autoreconf() {
    pushd $1
    autoreconf -fiv
    popd 
}

pacman -S --needed diffutils patch make mingw-w64-${runtime}-{lua,lua-luarocks,luajit,7zip,clang,pkgconf,autotools,libtool,icu,harfbuzz,cairo,pixman,libgd,freetype,libpng,graphite2,zziplib,mpfi,mpfr,gmp,potrace,libpaper,libjpeg-turbo,ghostscript,perl,perl-win32-console,perl-win32-shortcut,perl-win32-tieregistry,perl-win32-winerror,perl-win32api-registry,perl-file-which,perl-io-string}

# fetch sources
mkdir -p src
cd src
[ -d texlive-$tlversion-source ] || $wget https://mirrors.ctan.org/systems/texlive/Source/texlive-$tlversion-source.tar.xz
rm -rf texlive-$tlversion-source
tar xf texlive-$tlversion-source.tar.xz
cd texlive-$tlversion-source
patch -p1 < $workdir/patches/0006-workaround-pathconf.patch

# autoreconf
autoreconf -fiv
do_autoreconf "libs/lua53"
do_autoreconf "libs/luajit"
do_autoreconf "libs/xpdf"
do_autoreconf "libs/pplib"
do_autoreconf "libs/teckit"

do_autoreconf "texk/afm2pl"
do_autoreconf "texk/bibtex-x"
do_autoreconf "texk/chktex"
do_autoreconf "texk/cjkutils"
do_autoreconf "texk/detex"
do_autoreconf "texk/dtl"
do_autoreconf "texk/dvi2tty"
do_autoreconf "texk/dvidvi"
do_autoreconf "texk/dviljk"
do_autoreconf "texk/dviout-util"
do_autoreconf "texk/dvipdfm-x"
do_autoreconf "texk/dvipng"
do_autoreconf "texk/dvipos"
do_autoreconf "texk/dvipsk"
do_autoreconf "texk/dvisvgm"
do_autoreconf "texk/gregorio"
do_autoreconf "texk/kpathsea" 
do_autoreconf "texk/gsftopk"
do_autoreconf "texk/lcdf-typetools"
do_autoreconf "texk/makeindexk"
do_autoreconf "texk/makejvf"
do_autoreconf "texk/mendexk"
do_autoreconf "texk/musixtnt"
do_autoreconf "texk/ps2pk"
do_autoreconf "texk/psutils"
do_autoreconf "texk/ptexenc"
do_autoreconf "texk/seetexk"
do_autoreconf "texk/tex4htk"
do_autoreconf "texk/texlive"
do_autoreconf "texk/ttf2pk2"
do_autoreconf "texk/ttfdump"
do_autoreconf "texk/web2c" 
do_autoreconf "texk/upmendex"
do_autoreconf "texk/xdvik"

# build
mkdir -p build-woa
cd build-woa
../configure --prefix=$workdir/install/texlive  --disable-debug --disable-multiplatform --enable-static=no --enable-shared --disable-native-texlive-build --with-system-harfbuzz  --with-system-icu  --with-system-zziplib --with-system-graphite2 --with-system-cairo --with-system-pixman --with-system-gd --with-system-freetype2 --with-system-libpng  --with-system-zlib --with-system-mpfr --with-system-mpfi --with-system-gmp --with-system-potrace --with-system-libpaper --disable-luajittex --disable-luajithbtex --disable-mfluajit  
#--disable-luajittex --disable-luajithbtex --disable-mfluajit  
make -j $(nproc)

# build launchers (copy from MSYS2)
cp "libs/lua53/.libs/texlua.dll" ../texk/texlive/windows_mingw_wrapper
cp "libs/lua53/.libs/libtexlua53.dll.a" ../texk/texlive/windows_mingw_wrapper
pushd ../texk/texlive/windows_mingw_wrapper

echo '1 ICON "tlmgr.ico"'>texlive.rc
windres texlive.rc texlive.o

cc -Os -s -shared -Wl,--out-implib=librunscript.dll.a -o runscript.dll runscript_dll.c -L./ -ltexlua53
cc -Os -s -o runscript.exe runscript_exe.c texlive.o -L./ -lrunscript
cc -mwindows -Os -s -o wrunscript.exe wrunscript_exe.c texlive.o -L./ -lrunscript

cd context
cc -Os -s -shared -Wl,--out-implib=libmtxrun.dll.a -o mtxrun.dll mtxrun_dll.c
cc -Os -s -o mtxrun.exe mtxrun_exe.c -L./ -lmtxrun

popd

# install
make install-strip
make texlinks

# install mtxrun.dll (copy from MSYS2)
install -D -m755 "../texk/texlive/windows_mingw_wrapper/context/mtxrun.dll" \
    "$workdir/install/texlive/bin/mtxrun.dll"

for _script in context contextjit luatools mtxrun mtxrunjit texexec texmfstart
do
install -D -m755 "../texk/texlive/windows_mingw_wrapper/context/mtxrun.exe" \
    "$workdir/install/texlive/bin/${_script}.exe"
done

# copy dlls
cd $workdir/install/texlive/bin
# ldd *.exe | awk '{print $3}'| grep clang64 | xargs -I{} cp -u {} .
ldd *.exe | awk '{print $3}'| grep clangarm64 | xargs -I{} cp -u {} .

# symlinks
install -D -m755 euptex.exe $workdir/install/texlive/bin/uplatex.exe
install -D -m755 luatex.exe $workdir/install/texlive/bin/dvilualatex.exe
install -D -m755 luatex.exe $workdir/install/texlive/bin/dviluatex.exe
install -D -m755 luahbtex.exe $workdir/install/texlive/bin/lualatex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/amstex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/cslatex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/csplain.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/eplain.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/etex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/jadetex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/latex.exe
install -D -m755 tex.exe $workdir/install/texlive/bin/lollipop.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/mex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/mllatex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/mltex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/pdfetex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/pdfcslatex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/pdfcsplain.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/pdfjadetex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/pdflatex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/pdfmex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/pdfxmltex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/texsis.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/utf8mex.exe
install -D -m755 pdftex.exe $workdir/install/texlive/bin/xmltex.exe
install -D -m755 xetex.exe $workdir/install/texlive/bin/xelatex.exe
install -D -m755 epstopdf.exe $workdir/install/texlive/bin/repstopdf.exe

# package
cd ..
cp ./bin ./windows -r
7z a -mx9 texlive-mingw-arm64.7z windows
