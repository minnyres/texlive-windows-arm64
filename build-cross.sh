#!/bin/bash -e

prefix_dir=$PWD/texlive-windows-arm64
workdir=$PWD
mkdir -p "$prefix_dir/bin"
[ -z "$vcpkg_dir" ] && vcpkg_dir=$PWD/vcpkg
vcpkg_libs_dir=$vcpkg_dir/installed/arm64-mingw-dynamic
[ -z "$llvm_dir" ] && llvm_dir=$PWD/llvm-mingw

wget="wget -nc --progress=bar:force"
gitclone="git clone --depth=1 --recursive"

tlversion=20250308
tlcommithash=bc2b83b09ba191c546cc178682e475b3de7f37a6

export PATH=$llvm_dir/bin:$PATH
export TARGET=aarch64-w64-mingw32
export CC=$TARGET-gcc
export CXX=$TARGET-g++
export AR=$TARGET-ar
export NM=$TARGET-nm
export RANLIB=$TARGET-ranlib
export STRIP=$TARGET-strip

WARNING_FLAGS="-Werror=odr -Werror=strict-aliasing"
COMMON_FLAGS="-O2 -pipe -g0 -flto=thin ${WARNING_FLAGS}"
export USE="lto"
export CFLAGS="$COMMON_FLAGS -I$prefix_dir/include -I$vcpkg_libs_dir/include"
export CXXFLAGS=$CFLAGS
export CPPFLAGS="-I$prefix_dir/include -I$vcpkg_libs_dir/include -Wno-error=incompatible-function-pointer-types"
export LDFLAGS="-s -flto=thin -L$prefix_dir/lib -L$vcpkg_libs_dir/lib" # -Wl,--allow-multiple-definition"

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
    $TARGET-gcc $CXXFLAGS $LDFLAGS -DEXEPROG=\"$1.exe\" -o "$2.exe" callexe.c
    rm -rf "$prefix_dir/bin/$2.exe"
    install -D -m755 "$2.exe" "$prefix_dir/bin/$2.exe"
}

function buildcallscripts {
    $TARGET-g++ $CXXFLAGS $LDFLAGS -DSCRIPTLINK=\"$2\" -DINTERPRETER=\"$3.exe\" -o "$1.exe" -lkpathsea  callscripts.cpp
    rm -rf "$prefix_dir/bin/$1.exe"
    install -D -m755 "$1.exe" "$prefix_dir/bin/$1.exe"
}

function tlmklinks {
    cd ../texk/texlive/windows_mingw_wrapper
    buildcallexe pdftex amstex
    buildcallexe cluttex cllualatex
    buildcallexe cluttex clxelatex
    buildcallexe pdftex csplain
    buildcallexe luatex dvilualatex
    buildcallexe luatex dvilualatex-dev
    buildcallexe luatex dviluatex
    buildcallexe pdftex eplain
    buildcallexe euptex eptex
    buildcallexe pdftex etex
    buildcallexe hitex hilatex
    buildcallexe pdftex jadetex
    buildcallexe pdftex latex
    buildcallexe texdef latexdef
    buildcallexe pdftex latex-dev
    buildcallexe tex lollipop
    buildcallexe luatex luacsplain
    buildcallexe luahbtex lualatex
    buildcallexe luahbtex lualatex-dev
    buildcallexe pdftex mex
    buildcallexe pdftex mllatex
    buildcallexe pdftex mltex
    buildcallexe luahbtex optex
    buildcallexe upbibtex pbibtex
    buildcallexe pdftex pdfcsplain
    buildcallexe pdftex pdfetex
    buildcallexe pdftex pdfjadetex
    buildcallexe pdftex pdflatex
    buildcallexe pdftex pdflatex-dev
    buildcallexe pdftex pdfmex
    buildcallexe pdftex pdfxmltex
    buildcallexe updvitype pdvitype
    buildcallexe euptex platex
    buildcallexe euptex platex-dev
    buildcallexe uppltotf ppltotf
    buildcallexe euptex ptex
    buildcallexe uptftopl ptftopl
    buildcallexe epstopdf repstopdf
    buildcallexe mpost r-mpost
    buildcallexe pdfcrop rpdfcrop
    buildcallexe pmpost r-pmpost
    buildcallexe upmpost r-upmpost
    buildcallexe pdftex texsis
    buildcallexe euptex uplatex
    buildcallexe euptex uplatex-dev
    buildcallexe euptex uptex
    buildcallexe pdftex utf8mex
    buildcallexe xetex xelatex
    buildcallexe xetex xelatex-dev
    buildcallexe pdftex xmltex
    
    cd $workdir/wrappers
    buildcallscripts a2ping scripts/a2ping/a2ping.pl
    buildcallscripts a5toa4 scripts/pfarrei/a5toa4.tlu
    buildcallscripts afm2afm scripts/fontools/afm2afm perl
    buildcallscripts albatross scripts/albatross/albatross.sh
    buildcallscripts aom-fullref scripts/aomart/aom-fullref.pl
    buildcallscripts arara scripts/arara/arara.sh
    buildcallscripts arlatex scripts/bundledoc/arlatex perl
    buildcallscripts authorindex scripts/authorindex/authorindex perl
    buildcallscripts autoinst scripts/fontools/autoinst perl
    buildcallscripts bbl2bib scripts/crossrefware/bbl2bib.pl
    buildcallscripts bib2gls scripts/bib2gls/bib2gls.sh
    buildcallscripts bibcop scripts/bibcop/bibcop.pl
    buildcallscripts bibdoiadd scripts/crossrefware/bibdoiadd.pl
    buildcallscripts bibmradd scripts/crossrefware/bibmradd.pl
    buildcallscripts biburl2doi scripts/crossrefware/biburl2doi.pl
    buildcallscripts bibzbladd scripts/crossrefware/bibzbladd.pl
    buildcallscripts bookshelf-listallfonts scripts/bookshelf/bookshelf-listallfonts perl
    buildcallscripts bookshelf-mkfontsel scripts/bookshelf/bookshelf-mkfontsel perl
    buildcallscripts bundledoc scripts/bundledoc/bundledoc perl
    buildcallscripts cachepic scripts/cachepic/cachepic.tlu
    buildcallscripts checkcites scripts/checkcites/checkcites.lua
    buildcallscripts chklref scripts/chklref/chklref.pl
    buildcallscripts citeproc-lua scripts/citation-style-language/citeproc-lua.lua
    buildcallscripts cjk-gs-integrate scripts/cjk-gs-integrate/cjk-gs-integrate.pl
    buildcallscripts cluttex scripts/cluttex/cluttex.lua
    buildcallscripts convbkmk scripts/convbkmk/convbkmk.rb
    buildcallscripts convertgls2bib scripts/bib2gls/convertgls2bib.sh
    buildcallscripts ctanbib scripts/ctanbib/ctanbib texlua
    buildcallscripts ctanify scripts/ctanify/ctanify perl
    buildcallscripts ctan-o-mat scripts/ctan-o-mat/ctan-o-mat.pl
    buildcallscripts ctanupload scripts/ctanupload/ctanupload.pl
    buildcallscripts datatool2bib scripts/bib2gls/datatool2bib.sh
    buildcallscripts de-macro scripts/de-macro/de-macro python
    buildcallscripts depythontex scripts/pythontex/depythontex.py
    buildcallscripts deweb scripts/chktex/deweb.pl
    buildcallscripts diadia scripts/diadia/diadia.lua
    buildcallscripts digestif scripts/digestif/digestif.texlua
    buildcallscripts dosepsbin scripts/dosepsbin/dosepsbin.pl
    buildcallscripts dviasm scripts/dviasm/dviasm.py
    buildcallscripts dviinfox scripts/dviinfox/dviinfox.pl
    buildcallscripts e2pall scripts/texlive-extra/e2pall.pl
    buildcallscripts ebong scripts/ebong/ebong.py
    buildcallscripts edtx2dtx scripts/easydtx/edtx2dtx.pl
    buildcallscripts eolang scripts/eolang/eolang.pl
    buildcallscripts epspdf scripts/epspdf/epspdf.tlu
    buildcallscripts epspdftk scripts/epspdf/epspdftk.tcl
    buildcallscripts epstopdf scripts/epstopdf/epstopdf.pl
    buildcallscripts exceltex scripts/exceltex/exceltex perl
    buildcallscripts explcheck scripts/expltools/explcheck.lua
    buildcallscripts extractbb scripts/extractbb/extractbb.lua
    buildcallscripts extractres scripts/psutils/extractres.pl
    buildcallscripts fig4latex scripts/fig4latex/fig4latex perl
    buildcallscripts findhyph scripts/findhyph/findhyph perl
    buildcallscripts fmtutil scripts/texlive/fmtutil.pl
    buildcallscripts fmtutil-sys scripts/texlive/fmtutil-sys.sh
    buildcallscripts fmtutil-user scripts/texlive/fmtutil-user.sh
    buildcallscripts fragmaster scripts/fragmaster/fragmaster.pl
    buildcallscripts getmapdl scripts/getmap/getmapdl.lua
    buildcallscripts hyperxmp-add-bytecount scripts/hyperxmp/hyperxmp-add-bytecount.pl
    buildcallscripts includeres scripts/psutils/includeres.pl
    buildcallscripts installfont-tl scripts/installfont/installfont-tl bash
    buildcallscripts jamo-normalize scripts/kotex-utils/jamo-normalize.pl
    buildcallscripts jfmutil scripts/jfmutil/jfmutil.pl
    buildcallscripts kanji-config-updmap scripts/ptex-fontmaps/kanji-config-updmap.pl
    buildcallscripts kanji-config-updmap-sys scripts/ptex-fontmaps/kanji-config-updmap-sys.sh
    buildcallscripts kanji-config-updmap-user scripts/ptex-fontmaps/kanji-config-updmap-user.sh
    buildcallscripts kanji-fontmap-creator scripts/ptex-fontmaps/kanji-fontmap-creator.pl
    buildcallscripts ketcindy scripts/ketcindy/ketcindy.pl
    buildcallscripts komkindex scripts/kotex-utils/komkindex.pl
    buildcallscripts l3build scripts/l3build/l3build.lua
    buildcallscripts l3sys-query scripts/l3sys-query/l3sys-query.lua
    buildcallscripts latex2man scripts/latex2man/latex2man perl
    buildcallscripts latex2nemeth scripts/latex2nemeth/latex2nemeth bash
    buildcallscripts latexdiff scripts/latexdiff/latexdiff.pl
    buildcallscripts latexdiff-vc scripts/latexdiff/latexdiff-vc.pl
    buildcallscripts latex-git-log scripts/latex-git-log/latex-git-log perl
    buildcallscripts latexindent scripts/latexindent/latexindent.pl
    buildcallscripts latexminted scripts/minted/latexminted.py
    buildcallscripts latexmk scripts/latexmk/latexmk.pl
    buildcallscripts latexpand scripts/latexpand/latexpand perl
    buildcallscripts latex-papersize scripts/latex-papersize/latex-papersize.py
    buildcallscripts latexrevise scripts/latexdiff/latexrevise.pl
    buildcallscripts lily-glyph-commands scripts/lilyglyphs/lily-glyph-commands.py
    buildcallscripts lily-image-commands scripts/lilyglyphs/lily-image-commands.py
    buildcallscripts lily-rebuild-pdfs scripts/lilyglyphs/lily-rebuild-pdfs.py
    buildcallscripts listbib scripts/listbib/listbib bash
    buildcallscripts llmk scripts/light-latex-make/llmk.lua
    buildcallscripts ltx2crossrefxml scripts/crossrefware/ltx2crossrefxml.pl
    buildcallscripts ltx2unitxt scripts/bibtexperllibs/ltx2unitxt perl
    buildcallscripts ltximg scripts/ltximg/ltximg.pl
    buildcallscripts luafindfont scripts/luafindfont/luafindfont.lua
    buildcallscripts luaotfload-tool scripts/luaotfload/luaotfload-tool.lua
    buildcallscripts lwarpmk scripts/lwarp/lwarpmk.lua
    buildcallscripts make4ht scripts/make4ht/make4ht texlua
    buildcallscripts makedtx scripts/makedtx/makedtx.pl
    buildcallscripts makeglossaries scripts/glossaries/makeglossaries perl
    buildcallscripts makeglossaries-lite scripts/glossaries/makeglossaries-lite.lua
    buildcallscripts markdown2tex scripts/markdown/markdown2tex.lua
    buildcallscripts match_parens scripts/match_parens/match_parens ruby
    buildcallscripts mathspic scripts/mathspic/mathspic.pl
    buildcallscripts memoize-clean.pl scripts/memoize/memoize-clean.pl
    buildcallscripts memoize-clean.py scripts/memoize/memoize-clean.py
    buildcallscripts memoize-extract.pl scripts/memoize/memoize-extract.pl
    buildcallscripts memoize-extract.py scripts/memoize/memoize-extract.py
    buildcallscripts mf2pt1 scripts/mf2pt1/mf2pt1.pl
    buildcallscripts mk4ht scripts/tex4ht/mk4ht.pl
    buildcallscripts mkgrkindex scripts/mkgrkindex/mkgrkindex perl
    buildcallscripts mkjobtexmf scripts/mkjobtexmf/mkjobtexmf.pl
    buildcallscripts mkpic scripts/mkpic/mkpic perl
    buildcallscripts mkt1font scripts/accfonts/mkt1font perl
    buildcallscripts mktexlsr scripts/texlive/mktexlsr bash
    buildcallscripts mktexmf scripts/texlive/mktexmf bash
    buildcallscripts mktexpk scripts/texlive/mktexpk bash
    buildcallscripts mktextfm scripts/texlive/mktextfm bash
    buildcallscripts mptopdf scripts/context/perl/mptopdf.pl
    buildcallscripts m-tx scripts/m-tx/m-tx.lua
    buildcallscripts multibibliography scripts/multibibliography/multibibliography.pl
    buildcallscripts musixflx scripts/musixtex/musixflx.lua
    buildcallscripts musixtex scripts/musixtex/musixtex.lua
    buildcallscripts optexcount scripts/optexcount/optexcount python
    buildcallscripts ot2kpx scripts/fontools/ot2kpx perl
    buildcallscripts pamphletangler scripts/clojure-pamphlet/pamphletangler perl
    buildcallscripts pdfannotextractor scripts/pax/pdfannotextractor.pl
    buildcallscripts pdfatfi scripts/attachfile2/pdfatfi.pl
    buildcallscripts pdfcrop scripts/pdfcrop/pdfcrop.pl
    buildcallscripts pdflatexpicscale scripts/pdflatexpicscale/pdflatexpicscale.pl
    buildcallscripts pedigree scripts/pedigree-perl/pedigree.pl
    buildcallscripts perltex scripts/perltex/perltex.pl
    buildcallscripts pfarrei scripts/pfarrei/pfarrei.tlu
    buildcallscripts pkfix scripts/pkfix/pkfix.pl
    buildcallscripts pkfix-helper scripts/pkfix-helper/pkfix-helper perl
    buildcallscripts pmxchords scripts/pmxchords/pmxchords.lua
    buildcallscripts pn2pdf scripts/petri-nets/pn2pdf perl
    buildcallscripts ppmcheckpdf scripts/ppmcheckpdf/ppmcheckpdf.lua
    buildcallscripts ps2eps scripts/ps2eps/ps2eps.pl
    buildcallscripts ps4pdf scripts/pst-pdf/ps4pdf bash
    buildcallscripts psjoin scripts/psutils/psjoin.pl
    buildcallscripts pst2pdf scripts/pst2pdf/pst2pdf.pl
    buildcallscripts ptex2pdf scripts/ptex2pdf/ptex2pdf.lua
    buildcallscripts purifyeps scripts/purifyeps/purifyeps perl
    buildcallscripts pygmentex scripts/pygmentex/pygmentex.py
    buildcallscripts pythontex scripts/pythontex/pythontex.py
    buildcallscripts rubikrotation scripts/rubik/rubikrotation.pl
    buildcallscripts rungs scripts/texlive/rungs.lua
    buildcallscripts runtexshebang scripts/runtexshebang/runtexshebang.lua
    buildcallscripts spix scripts/spix/spix.py
    buildcallscripts splitindex scripts/splitindex/splitindex.pl
    buildcallscripts sqltex scripts/sqltex/sqltex perl
    buildcallscripts srcredact scripts/srcredact/srcredact.pl
    buildcallscripts sty2dtx scripts/sty2dtx/sty2dtx.pl
    buildcallscripts svn-multi scripts/svn-multi/svn-multi.pl
    buildcallscripts tex4ebook scripts/tex4ebook/tex4ebook texlua
    buildcallscripts texaccents scripts/texaccents/texaccents.sno snobol4
    buildcallscripts texblend scripts/texblend/texblend texlua
    buildcallscripts texcount scripts/texcount/texcount.pl
    buildcallscripts texdef scripts/texdef/texdef.pl
    buildcallscripts texdiff scripts/texdiff/texdiff perl
    buildcallscripts texdirflatten scripts/texdirflatten/texdirflatten perl
    buildcallscripts texdoc scripts/texdoc/texdoc.tlu
    buildcallscripts texdoctk scripts/texdoctk/texdoctk.pl
    buildcallscripts texfindpkg scripts/texfindpkg/texfindpkg.lua
    buildcallscripts texfot scripts/texfot/texfot.pl
    buildcallscripts texindy scripts/xindy/texindy.pl
    buildcallscripts texliveonfly scripts/texliveonfly/texliveonfly.py
    buildcallscripts texloganalyser scripts/texloganalyser/texloganalyser perl
    buildcallscripts texlogfilter scripts/texlogfilter/texlogfilter perl
    buildcallscripts texlogsieve scripts/texlogsieve/texlogsieve texlua
    buildcallscripts texosquery scripts/texosquery/texosquery.sh
    buildcallscripts texosquery-jre5 scripts/texosquery/texosquery-jre5.sh
    buildcallscripts texosquery-jre8 scripts/texosquery/texosquery-jre8.sh
    buildcallscripts texplate scripts/texplate/texplate.sh
    buildcallscripts thumbpdf scripts/thumbpdf/thumbpdf.pl
    buildcallscripts tlcockpit scripts/tlcockpit/tlcockpit.sh
    buildcallscripts tlshell scripts/tlshell/tlshell.tcl
    buildcallscripts ttf2kotexfont scripts/kotex-utils/ttf2kotexfont.pl
    buildcallscripts typog-grep scripts/typog/typog-grep.pl
    buildcallscripts ulqda scripts/ulqda/ulqda.pl
    buildcallscripts updmap scripts/texlive/updmap.pl
    buildcallscripts updmap-sys scripts/texlive/updmap-sys.sh
    buildcallscripts updmap-user scripts/texlive/updmap-user.sh
    buildcallscripts urlbst scripts/urlbst/urlbst perl
    buildcallscripts vpe scripts/vpe/vpe.pl
    buildcallscripts vpl2ovp scripts/accfonts/vpl2ovp perl
    buildcallscripts vpl2vpl scripts/accfonts/vpl2vpl perl
    buildcallscripts webquiz scripts/webquiz/webquiz.py
    buildcallscripts xelatex-unsafe scripts/texlive-extra/xelatex-unsafe.sh
    buildcallscripts xetex-unsafe scripts/texlive-extra/xetex-unsafe.sh
    buildcallscripts xindex scripts/xindex/xindex.lua
    buildcallscripts yplan scripts/yplan/yplan perl
}

mkdir -p src
cd src

# build gsl
gsl_ver=2.8
[ -d gsl-$gsl_ver ] || $wget https://ftpmirror.gnu.org/gsl/gsl-$gsl_ver.tar.gz
tar xf gsl-$gsl_ver.tar.gz
cd gsl-$gsl_ver
./configure $commonflags 
gnumakeplusinstall
rm $prefix_dir/bin/gsl*

# texlive
usetlsrctarball=1
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
sed -i 's|"texlua"|"texluajit"|'  texk/texlive/windows_mingw_wrapper/runscript_dll.c
mkdir build-woa
cd build-woa
mkdir -p texk/web2c
cp ../texk/web2c/hitexdir/hitables.c texk/web2c
../configure $commonflags --disable-native-texlive-build --disable-cxx-runtime-hack --disable-multiplatform --with-system-harfbuzz --with-system-icu --with-system-graphite2 --with-system-cairo --with-system-pixman --with-system-gd --with-system-freetype2 --with-system-libpng  --with-system-zlib --enable-xindy --disable-xindy-docs --disable-xindy-rules --enable-tex-synctex --enable-mflua-nowin --enable-mfluajit-nowin
make -j $(nproc)

# build launchers (copy from MSYS2)
pushd ../texk/texlive/windows_mingw_wrapper

echo '1 ICON "tlmgr.ico"'>texlive.rc
$TARGET-windres texlive.rc texlive.o

$TARGET-gcc -Os -s -shared -Wl,--out-implib=librunscript.dll.a -o runscript.dll runscript_dll.c
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
LDFLAGS="$LDFLAGS gc/.libs/libgccpp.a -lshlwapi -lole32" ./configure $commonflags --enable-texlive-build 
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