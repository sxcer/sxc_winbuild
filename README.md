sxc_winbuild
============

Automated building of sexcoin-qt (and dependencies) on Windows using msys2

This script is basically an automation of the awesome Windows build
instructions that user nitrogenetics posted and maintains at
bitcointalk.org:

  https://bitcointalk.org/index.php?topic=149479.0

It manages to build everything from an msys2 prompt, but this is most
likely a function of msys2 and not any real improvements in nitrogenetics'
instructions.

In the simplest case, running this script with no args builds everything all
the way up to and including sexcoin-qt.

It also provides a few arguments to allow for repeating or focusing on
specific parts of the build process.

Building of bitcoin-qt is supported, but disabled by default. You simply
need to uncomment one line(adding "BTC" to $PKGS). In the same manner,
you can disable the sexcoin-qt build. With minimal extra work you can add
a new "Package Definition" for another altcoin. Coins at v0.9 or higher
will be easiest to adapt I think.

This script requires msys2 64Bit.

Installation of msys2 64 Bit to the default c:\msys64 directory is described
here:
          http://msys2.github.io/

or, simply download and run this installer(same as linked to at site above):

http://sourceforge.net/projects/msys2/files/Base/x86_64/msys2-x86_64-20140910.exe/download

Once msys2 is installed, launch (double-click) c:\msys64\mingw64_shell.bat

To retrieve the latest version of the script, in the terminal type:
     wget https://github.com/sxcer/sxc_winbuild/raw/master/sxc_winbuild.sh

If you do not edit BASEDIR near the top of the script, C:\src will be used
to build in. All downloads, unpacking and building will be done in this
directory or subdirectories of it.

Launch the script (with no args to simply "build all"):

     sh sxc_winbuild.sh

It will take a while to download all packages and build (including
building Qt5 from source) so be prepared to wait.

There are a few arguments you can pass to the script to perform (or re-do)
individual parts of the build process, or see the build commands so you can
build something yourself outside the script. Just run with "help" argument 
to see a list of options.

If you want the coin build to build the *coin.exe installer in addition to
*coin-qt.exe, you need to have NSIS installed (in Windows)
See http://nsis.sf.net for NSIS installer info.

Building with NSIS build is untested, but should be autodetected by configure script for
v0.9+ coins

# By default this script will use C:\src (/c/src in msys2 syntax) as it's base dir.
