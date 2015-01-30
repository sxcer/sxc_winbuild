sxc_winbuild
============

Description
------------
Automated building of Sexcoin or Bitcoin (and dependencies) on Windows
using msys2.

This script is basically an automation of the awesome Windows build
instructions that user nitrogenetics posted and maintains at
bitcointalk.org:

  https://bitcointalk.org/index.php?topic=149479.0

It manages to build everything from an msys2 prompt. This is most likely
a function of msys2 and not any real improvements in nitrogenetics'
instructions.

It provides a few options to allow for repeating or focusing on
specific parts of the build process.

With minimal extra work you can add a new "Package Definition" for another
altcoin. Coins at v0.9 or higher will be easiest to adapt.


Requirements
------------
This script requires msys2 64Bit.

Installation of msys2 64 Bit to the default c:\msys64 directory is described
here(install 64bit version to c:\msys64):

    http://msys2.github.io/


Getting MINGW64 shell setup
------------
Once msys2 is installed, double-click:

    C:\msys64\mingw64_shell.bat
    Note: There are 3 shell starting .bat files in C:\msys64
          but only mingw64_shell.bat will work for this script.

    # Update pacman package databases
    # In the shell type:
    pacman -Sy

    # Install wget and download the script
    pacman -S wget
    wget https://github.com/sxcer/sxc_winbuild/raw/master/sxc_winbuild.sh

    # Check if script runs
    sh sxc_winbuild.sh help


One line build SXCNG or BTC
------------
You are probably most interested in:

    sh sxc_winbuild.sh build SXCNG

    # or

    sh sxc_winbuild.sh build BTC

It will take a while to download all packages and build (including
building Qt5 from source) so be prepared to wait.


Buildable Packages
-----------
You can see all the packages the script knows about with:

    sh sxc_winbuild.sh pkgs

Most of the packages the script can build are dependencies and are included
automatically when you to specify building BTC SXCNG etc.


Build Directory
------------
By default all building will be done in directory named "src" in the directory
you run the script from. If you would like to alter that, edit $CUSTOM_BASEDIR
near the top of the script.

You can see what directory the script will use with:

    sh sxc_winbuild.sh dirs

An example of the default build directory selection:

    sxcer@gcore3 MINGW64 ~/src/sxc_winbuild
    $ sh sxc_winbuild.sh dirs
    Using default directory: /home/sxcer/src/sxc_winbuild/src
     BASEDIR=/home/sxcer/src/sxc_winbuild/src
    CACHEDIR=/home/sxcer/src/sxc_winbuild/src/.download_cache

    sxcer@gcore3 MINGW64 ~/src/sxc_winbuild
    $


Other
------------
There are a few arguments you can pass to the script to perform (or repeat)
individual parts of the build process, or see the build commands so you can
build something yourself outside the script. Just run with "help" argument 
to see a list of options.

If you want the coin build to build the *coin.exe installer in addition to
*coin-qt.exe, you need to have NSIS installed (in Windows)
See http://nsis.sf.net for NSIS installer info.

Building with NSIS is untested but should be autodetected by configure script
for v0.9+ coins
