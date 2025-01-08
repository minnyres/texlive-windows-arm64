# texlive-mingw-arm64

This project distributes TeX Live build for Windows Arm64. The binary files are available at the [release page](https://github.com/minnyres/texlive-mingw-arm64/releases). Note that the build is still at experimental stage: it basically works but not full ready for producation use.

## How to install
+ First, install the x64 version of TeX Live.
+ Then, replace the x64 binaries with the Arm64 binaries. Open the installation directory of TeX Live, i.e. `F:\texlive\2024`. The x64 binaries are places in the sub-directory `bin\windows`. Rename the folder `windows` to `windows-x64`. Download and extract the Arm64 build. Put the extracted `windows` folder under `bin` and then you got the binary files replaced.
+ Some settings for libpaper. Create a folder `.config` under the user home directory, which is `C:\Users\<user-name>\` for Windows. Download the [paperspecs file](https://github.com/minnyres/texlive-mingw-arm64/blob/main/paperspecs) to the `.config` folder.

## How to build
It is currently built with the clang arm64 toolchain from MSYS2 project and has to be done on Windows 11 Arm64.
+ First, install MSYS2.
+ Open MSYS2 CLANGARM64 environment

```
pacman -S git
git clone https://github.com/minnyres/texlive-mingw-arm64
cd texlive-mingw-arm64
./build.sh
```

## Known issues
Some features are not supported yet compared with the full x64 build. Don't worry, you can still copy the x64 binary files to the Arm64 binary file folder if any program is missing or not working... 
+ LuaJit is not built 
+ Since luaffi library does not support Windows Arm64, some utilities do not work, including `latexmk`. `epstopdf` also does not work so you cannot include eps files in a document.
