# texlive-windows-arm64

This project distributes TeX Live build for Windows Arm64. The binary files are available at the [release page](https://github.com/minnyres/texlive-windows-arm64/releases).

## How to install
### Step 1: Install TeX Live 2025

First, install TeX Live 2025 via the [iso file](https://mirrors.ctan.org/systems/texlive/Images) or [network install](https://tug.org/texlive/acquire-netinstall.html). This installs the binaries for x64 Windows, which will later be replaced by the Arm64 binaries.

It is recommended to make a [portable install](https://tex.stackexchange.com/questions/381094/how-to-install-a-portable-tex-live-in-windows). The installation path of TeX Live should have no non-ascii characters, and had better have no space. 

### Step 2: Install Arm64 binaries

Now, we install the binaries for Arm64 Windows as a [custom binary set](https://tug.org/texlive/custom-bin.html).

Open Windows Powershell and get into the installation path of TeX Live, e.g. `c:/texlive/2025`, via `cd` command
```
cd c:/texlive/2025
```
Raname the x64 binary folder in Powershell
```
cd bin
mv .\windows\ .\windows-x64
```
Download the [Arm64 binaries](https://github.com/minnyres/texlive-windows-arm64/releases/download/build-20250310/texlive-mingw-arm64-20250310.tar.gz) with a web browder, or with `curl.exe` command in Powershell
``` 
curl.exe -L https://github.com/minnyres/texlive-windows-arm64/releases/download/build-20250310/texlive-mingw-arm64-20250310.tar.gz -o texlive-mingw-arm64.tar.gz
```
Extract the archive in Powershell
```
tar xf .\texlive-mingw-arm64.tar.gz
```
Finally, add path of the Arm64 binary set to the environment variable `PATH` in Powershell if you have not done it yet
```
$path1=[System.Environment]::GetEnvironmentVariable('PATH', 'User')
[System.Environment]::SetEnvironmentVariable('PATH',"$path1;$pwd/windows", 'User')
```
### Step 3: Install and setup MSYS2 (Optional)

TeX Live includes many scripts that need external programs to interpret, such as python and perl. We can install native Arm64 build of these programs via [MSYS2](https://www.msys2.org/).

MSYS2 can be installed from its [installer](https://www.msys2.org/docs/installer/). Once the installtion is complete, open the MSYS2 terminal and type the following commands to install perl, ghostscript, ruby, tcl/tk and python
```
pacman -S mingw-w64-clang-aarch64-{perl-modules,ghostscript,ruby,tk,python}
```
To work with the tools in MSYS2, you need to define the environment variable `MSYS2_PATH_FOR_TEXLIVE`. Come back to Powershell and type the command
```
[System.Environment]::SetEnvironmentVariable('MSYS2_PATH_FOR_TEXLIVE', 'C:\msys64\', 'User')
```
where `C:\msys64\` should be replaced by the installation path of MSYS2.


## How to build
We are using GitHub actions to build TeX Live for Windows Arm64. The build scripts are in public domain and can be found [here](https://github.com/minnyres/texlive-windows-arm64/blob/main/.github/workflows/release.yml).

TeX Live is cross compiled on GNU/Linux with the [llvm-mingw](https://github.com/mstorsjo/llvm-mingw) toolchain. ConTeXt are built with MSVC on x64 Windows. 

## Issues
Some programs are not built compared with the x64 build. If anything is missing or not working, you are welcomed to post [issues](https://github.com/minnyres/texlive-windows-arm64/issues).
