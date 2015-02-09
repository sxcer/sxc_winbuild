#/bin/sh
# sxc_winbuild.sh v0.7 - Automated building of sexcoin-qt (and dependencies)
#                        on Windows using msys2
# Latest here: https://github.com/sxcer/sxc_winbuild          sxcerr@gmail.com
#
# This script must be run from a msys2 MINGW64 shell
#
#                  *msys2 Is Required (not msys)*

# Installation of msys2 x86_64 to the default c:\msys64 directory
# is described here:
#          http://msys2.github.io/
#
# After installation, double-click c:\mingw64\mingw64_shell.bat and type:
#     pacman -Sy
#     pacman -S wget
#     wget https://github.com/sxcer/sxc_winbuild/raw/master/sxc_winbuild.sh
#
# to easily get this script into the shell.
#
# Running:
#     sh sxc_winbuild.sh pkgs 
#
# will show a list of packages that can be built. You're probably most
# interested in SXCNG or BTC (which will include all the deps)
#
#     sh sxc_winbuild.sh build SXCNG
#
# It will take a long while to download all packages and build (including
# building Qt5 from source) so be prepared to wait.
#
#
# Build Directory
# By default this script will use "./src". Assuming you just installed msys2
# and ran the shell shortcut this is probably /home/<username>/src.
#
# The actual location from windows viewpoint is C:\msys64\home\<username>\src
# From within msys shells, / is equivalent to c:\msys64 so:
#    /home/<username>/src
# but also accessible using the absolute path (in msys2 syntax):
#    /c/msys64/home/<username>/src
#
# Specify a different directory here. Avoid dirs with spaces, keep it simple.
# Keep in mind that if there is a HOME env var set in windows, it will
# propagate to your msys2 environment and your home dir will not be the msys2
# default of /home/<username>
# Do NOT use a path with whitespace, libtool breaks in Protobuf build if there
# is whitespace
CUSTOM_BASEDIR=
#CUSTOM_BASEDIR=/c/src
#CUSTOM_BASEDIR=/c/Users/jsmith/src
#CUSTOM_BASEDIR=/x/src
#CUSTOM_BASEDIR=/c/tmp/src


##########################################################################
# Below here, you should know a little about what you are doing to edit. #
##########################################################################


##############################################################################
#
# Package Definition Functions
#
# Definitions for each package are wrapped in a single function per pkg
#    init_<PKG>_vars()
#
# All they really do is set variables with values that define a package, name,
# URL for download, MD5 of tarball, build commands, etc.
#
# Defining them as functions allows them to be invoked later in the script than
# the physical ordering (by line number) would indicate.
#
# BASEDIR, toolchain, and even order of defining the package variables affect
# some package variables, so this also let's us control when and in what order
# package variables are set.
#
#
# PKG_URL and PKG_SRC are concatenated to form full URL for wget call
# PKG_MD5 is optional, if present it is checked against source package MD5
# PKG_UNPACKDIR only needs to be defined if the sourceball unpacks to
# something other than:
#     <PKG>-<PKG_VER>
# For example:
#     boost source file (7zip archive) unpacks to boost_1_5_55,
#     BOOST is defined as boost
#     BOOST_VER is defined as 1_55_0
#     But the source package does not unpack to boost-1_55_0, it unpacks to
#     boost_1_55_0.
#     So, you must defined BOOST_UNPACKDIR as "boost_1_55_0" or the script
#     will not be able to find where the unpacked source tree.
#
###############################################################################

#Master list of Packages
MASTERPKGLIST="OPENSSL BDB BOOST MINIUPNPC LIBPNG QRENCODE PROTOBUF QT QTTOOLS\
 BTC SXCNG SXC"

 
# Define <PKG>_DEPS outside of functions that define other package vars.
#
# Some package vars may depend on vars that are defined by dependency packages.
#
# So we need to know the dependencies for a package before we initialize it's
# variables.
# If a package has no dependencies, ther is no need to define an empty var.
# For example OPENSSL_DEPS="" is not necessary.

QRENCODE_DEPS="LIBPNG"
QT_DEPS="LIBPNG OPENSSL"
QTTOOLS_DEPS="QT"
BTC_DEPS="OPENSSL BDB BOOST MINIUPNPC LIBPNG QRENCODE PROTOBUF QT QTTOOLS"
SXCNG_DEPS="OPENSSL BDB BOOST MINIUPNPC LIBPNG QRENCODE PROTOBUF QT QTTOOLS"
SXC_DEPS="OPENSSL BDB BOOST MINIUPNPC LIBPNG QRENCODE QT QTTOOLS"
BTCNOGUI_DEPS="OPENSSL BDB BOOST MINIUPNPC PROTOBUF"

function init_OPENSSL_vars() {
OPENSSL=openssl
OPENSSL_VER=1.0.1l
OPENSSL_URL=http://www.openssl.org/source
OPENSSL_SRC=${OPENSSL}-${OPENSSL_VER}.tar.gz
OPENSSL_MD5=cdb22925fc9bc97ccbf1e007661f2aa6
OPENSSL_MSYS2_BUILDCMDS="# openssl build commands
./Configure no-zlib no-shared no-dso no-krb5 no-camellia no-capieng no-cast \\
            no-cms no-dtls1 no-gost no-gmp no-heartbeats no-idea no-jpake \\
            no-md2 no-mdc2 no-rc5 no-rdrand no-rfc3779 no-rsax no-sctp \\
            no-seed no-sha0 no-static_engine no-whirlpool no-rc2 no-rc4 \\
            no-ssl2 no-ssl3 mingw64
make"
}

function init_BDB_vars() {
BDB=db
BDB_VER=4.8.30.NC
BDB_URL=http://download.oracle.com/berkeley-db
BDB_SRC=${BDB}-${BDB_VER}.tar.gz
BDB_MD5=a14a5486d6b4891d2434039a0ed4c5b7
BDB_MSYS2_BUILDCMDS="# bdb 4.8.30.NC build commands
cd build_unix
../dist/configure \\
    --enable-mingw \\
    --enable-cxx \\
    --disable-shared \\
    --disable-replication
make -j$((NPROC*2))"
}


function init_BOOST_vars() {
BOOST=boost
BOOST_VER=1_57_0
BOOST_URL=http://sourceforge.net/projects/boost/files/boost/1.57.0
BOOST_SRC=${BOOST}_${BOOST_VER}.tar.bz2
BOOST_MD5=1be49befbdd9a5ce9def2983ba3e7b76
BOOST_UNPACKDIR="${BOOST}_${BOOST_VER}"
GCC_VER_TOKEN=$(/mingw64/bin/gcc -v 2>&1 | \
                awk '/gcc version/{print $3}' | \
                awk -F. '{print $1 $2}')
BOOST_SUFFIX=mgw${GCC_VER_TOKEN}-mt-s-${BOOST_VER%%_0}
BOOST_MSYS2_BUILDCMDS="# boost build commands
./bootstrap.bat mingw
./b2 -j$((NPROC*2)) \\
    --build-type=complete \\
    --with-chrono \\
    --with-filesystem \\
    --with-program_options \\
    --with-system \\
    --with-thread toolset=gcc \\
    variant=release \\
    link=static \\
    threading=multi \\
    runtime-link=static \\
    stage"
}


function init_MINIUPNPC_vars() {
MINIUPNPC=miniupnpc
MINIUPNPC_VER=1.9.20141128
MINIUPNPC_URL=http://miniupnp.free.fr/files/download.php?file=
MINIUPNPC_SRC=${MINIUPNPC}-${MINIUPNPC_VER}.tar.gz
MINIUPNPC_MD5=3d2fcd3a3157f0d68343dc008e9196d4
MINIUPNPC_MSYS2_BUILDCMDS="# miniupnpc build commands
#by default symlinks just copy in msys2
#so remove any miniupnpc dir first
[ -d ../miniupnpc ] && rm -rf ../miniupnpc
mingw32-make.exe -j$((NPROC*2)) -f Makefile.mingw init upnpc-static
cd ..
ln -s miniupnpc-${MINIUPNPC_VER} miniupnpc"
}


function init_PROTOBUF_vars() {
PROTOBUF=protobuf
PROTOBUF_VER=2.6.1
PROTOBUF_URL=https://github.com/google/protobuf/releases/download/v2.6.1
PROTOBUF_SRC=${PROTOBUF}-${PROTOBUF_VER}.tar.bz2
PROTOBUF_MD5=11aaac2d704eef8efd1867a807865d85
PROTOBUF_MSYS2_BUILDCMDS="# protobuf build commands
./configure --disable-shared
make"
}


function init_LIBPNG_vars() {
LIBPNG=libpng
LIBPNG_VER=1.6.16
LIBPNG_URL=http://download.sourceforge.net/libpng
LIBPNG_URL=ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16
LIBPNG_SRC=${LIBPNG}-${LIBPNG_VER}.tar.xz
LIBPNG_MD5=23b7286b5d4a86de950fd2ffc5cac742
LIBPNG_MSYS2_BUILDCMDS="# libpng build commands
./configure --disable-shared
make -j$((NPROC*2))
cp ./.libs/libpng16.a ./.libs/libpng.a"
}


function init_QRENCODE_vars() {
QRENCODE=qrencode
QRENCODE_VER=3.4.4
QRENCODE_URL=http://fukuchi.org/works/qrencode
QRENCODE_SRC=${QRENCODE}-${QRENCODE_VER}.tar.gz
QRENCODE_MD5=be545f3ce36ea8fbb58612d72c4222de
QRENCODE_MSYS2_BUILDCMDS="# qrencode build commands
      LIBS='../libpng-${LIBPNG_VER}/.libs/libpng.a /mingw64/lib/libz.a' \\
png_CFLAGS='-I../libpng-${LIBPNG_VER}' \\
  png_LIBS='-L../libpng-${LIBPNG_VER}/.libs'  \\
./configure --enable-static --disable-shared --without-tools
make -j$((NPROC*2))"
}


function init_QT_vars() {
QT=qtbase
QT_VER=5.3.2
QT_URL=http://download.qt-project.org/official_releases/qt/5.3/5.3.2/submodules
QT_SRC=qtbase-opensource-src-${QT_VER}.zip
QT_MD5=1a81aafd9d63168e9d0d1056ae0cc5d2
QT_UNPACKDIR=qtbase-opensource-src-5.3.2
QT_MSYS2_BUILDCMDS="# qtbase build commands
mingw32-make confclean
./configure.exe  -I ${BASEDIR}/libpng-${LIBPNG_VER} \\
                 -I ${BASEDIR}/openssl-${OPENSSL_VER}/include \\
                 -L ${BASEDIR}/libpng-${LIBPNG_VER}/.libs \\
                 -L ${BASEDIR}/openssl-${OPENSSL_VER} \\
                 -openssl \\
                 -nomake examples \\
                 -nomake libs \\
                 -nomake tools \\
                 -release -opensource \\
                 -confirm-license \\
                 -static \\
                 -make libs \\
                 -no-sql-sqlite \\
                 -no-opengl \\
                 -system-zlib \\
                 -qt-pcre \\
                 -no-icu \\
                 -no-gif \\
                 -system-libpng \\
                 -no-libjpeg \\
                 -no-freetype \\
                 -no-angle \\
                 -no-vcproj \\
                 -no-dbus \\
                 -no-audio-backend \\
                 -no-wmf-backend \\
                 -no-qml-debug
mingw32-make -j$((NPROC*2))"
}


function init_QTTOOLS_vars() {
QTTOOLS=qttools
QTTOOLS_VER=5.3.2
QTTOOLS_URL=http://download.qt-project.org/official_releases/qt/5.3/5.3.2/submodules
QTTOOLS_SRC=qttools-opensource-src-${QT_VER}.zip
QTTOOLS_MD5=d2152ab42db37f1a8ef98a3fcce34615
QTTOOLS_UNPACKDIR=qttools-opensource-src-5.3.2
QTTOOLS_MSYS2_BUILDCMDS="# qttools build commands
export PATH=\"$PATH:${BASEDIR}/${QT_UNPACKDIR}/bin\"
qmake.exe qttools.pro
mingw32-make -j$((NPROC*2))"
}


function init_BTC_vars() {
BTC=bitcoin
BTC_VER=0.9.3
BTC_URL=https://github.com/bitcoin/bitcoin/archive
BTC_SRC=v0.9.3.zip
BTC_MD5=cb88d813b89372de2d4012fa9c7ba609
BTC_MSYS2_BUILDCMDS="# bitcoin build commands
./autogen.sh
CPPFLAGS=\" \\
    -I${BASEDIR}/boost_${BOOST_VER} \\
    -I${BASEDIR}/db-${BDB_VER}/build_unix \\
    -I${BASEDIR}/openssl-${OPENSSL_VER}/include \\
    -I${BASEDIR} \\
    -I${BASEDIR}/protobuf-${PROTOBUF_VER}/src \\
    -I${BASEDIR}/libpng-${LIBPNG_VER} \\
    -I${BASEDIR}/qrencode-${QRENCODE_VER}\" \\
LDFLAGS=\" \\
    -L${BASEDIR}/boost_${BOOST_VER}/stage/lib \\
    -L${BASEDIR}/db-${BDB_VER}/build_unix \\
    -L${BASEDIR}/openssl-${OPENSSL_VER} \\
    -L${BASEDIR}/miniupnpc-${MINIUPNPC_VER} \\
    -L${BASEDIR}/protobuf-${PROTOBUF_VER}/src/.libs \\
    -L${BASEDIR}/libpng-${LIBPNG_VER}/.libs \\
    -L${BASEDIR}/qrencode-${QRENCODE_VER}/.libs\" \\
./configure \\
    --disable-upnp-default \\
    --disable-tests \\
    --with-qt-incdir=${BASEDIR}/${QT_UNPACKDIR}/include \\
    --with-qt-libdir=${BASEDIR}/${QT_UNPACKDIR}/lib \\
    --with-qt-bindir=${BASEDIR}/${QT_UNPACKDIR}/bin \\
    --with-qt-plugindir=${BASEDIR}/${QT_UNPACKDIR}/plugins \\
    --with-boost-system=$BOOST_SUFFIX \\
    --with-boost-filesystem=$BOOST_SUFFIX \\
    --with-boost-program-options=$BOOST_SUFFIX \\
    --with-boost-thread=$BOOST_SUFFIX \\
    --with-boost-chrono=$BOOST_SUFFIX \\
    --with-protoc-bindir=${BASEDIR}/protobuf-${PROTOBUF_VER}/src
make -j$((NPROC*2))
strip src/bitcoin-cli.exe
strip src/bitcoind.exe
strip src/qt/bitcoin-qt.exe"
}


function init_BTCNOGUI_vars() {
BTCNOGUI=bitcoin
BTCNOGUI_VER=0.9.3
BTCNOGUI_URL=https://github.com/bitcoin/bitcoin/archive
BTCNOGUI_SRC=v0.9.3.zip
BTCNOGUI_MD5=cb88d813b89372de2d4012fa9c7ba609
BTCNOGUI_MSYS2_BUILDCMDS="# bitcoin build commands
./autogen.sh
CPPFLAGS=\" \\
    -I${BASEDIR}/boost_${BOOST_VER} \\
    -I${BASEDIR}/db-${BDB_VER}/build_unix \\
    -I${BASEDIR}/openssl-${OPENSSL_VER}/include \\
    -I${BASEDIR} \\
    -I${BASEDIR}/protobuf-${PROTOBUF_VER}/src\" \\
LDFLAGS=\" \\
    -L${BASEDIR}/boost_${BOOST_VER}/stage/lib \\
    -L${BASEDIR}/db-${BDB_VER}/build_unix \\
    -L${BASEDIR}/openssl-${OPENSSL_VER} \\
    -L${BASEDIR}/miniupnpc-${MINIUPNPC_VER} \\
    -L${BASEDIR}/protobuf-${PROTOBUF_VER}/src/.libs\" \\
./configure \\
    --disable-upnp-default \\
    --disable-tests \\
    --with-boost-system=$BOOST_SUFFIX \\
    --with-boost-filesystem=$BOOST_SUFFIX \\
    --with-boost-program-options=$BOOST_SUFFIX \\
    --with-boost-thread=$BOOST_SUFFIX \\
    --with-boost-chrono=$BOOST_SUFFIX \\
    --with-protoc-bindir=${BASEDIR}/protobuf-${PROTOBUF_VER}/src
make -j$((NPROC*2))
strip src/bitcoin-cli.exe
strip src/bitcoind.exe"
}


function init_SXCNG_vars() {
SXCNG=sexcoin-ng
SXCNG_VER=master
SXCNG_URL=https://github.com/sxcer/sexcoin-ng/archive
SXCNG_SRC=master.zip
SXCNG_MD5=7d4fbac730b0a3eb93d858978021e8d1
SXCNG_MSYS2_BUILDCMDS="# sexcoin-ng build commands
./autogen.sh
CPPFLAGS=\" \\
    -I${BASEDIR}/boost_${BOOST_VER} \\
    -I${BASEDIR}/db-${BDB_VER}/build_unix \\
    -I${BASEDIR}/openssl-${OPENSSL_VER}/include \\
    -I${BASEDIR} \\
    -I${BASEDIR}/protobuf-${PROTOBUF_VER}/src \\
    -I${BASEDIR}/libpng-${LIBPNG_VER} \\
    -I${BASEDIR}/qrencode-${QRENCODE_VER}\" \\
LDFLAGS=\" \\
    -L${BASEDIR}/boost_${BOOST_VER}/stage/lib \\
    -L${BASEDIR}/db-${BDB_VER}/build_unix \\
    -L${BASEDIR}/openssl-${OPENSSL_VER} \\
    -L${BASEDIR}/miniupnpc-${MINIUPNPC_VER} \\
    -L${BASEDIR}/protobuf-${PROTOBUF_VER}/src/.libs \\
    -L${BASEDIR}/libpng-${LIBPNG_VER}/.libs \\
    -L${BASEDIR}/qrencode-${QRENCODE_VER}/.libs\" \\
./configure \\
    --disable-upnp-default \\
    --disable-tests \\
    --with-qt-incdir=${BASEDIR}/${QT_UNPACKDIR}/include \\
    --with-qt-libdir=${BASEDIR}/${QT_UNPACKDIR}/lib \\
    --with-qt-bindir=${BASEDIR}/${QT_UNPACKDIR}/bin \\
    --with-qt-plugindir=${BASEDIR}/${QT_UNPACKDIR}/plugins \\
    --with-boost-system=$BOOST_SUFFIX \\
    --with-boost-filesystem=$BOOST_SUFFIX \\
    --with-boost-program-options=$BOOST_SUFFIX \\
    --with-boost-thread=$BOOST_SUFFIX \\
    --with-boost-chrono=$BOOST_SUFFIX \\
    --with-protoc-bindir=${BASEDIR}/protobuf-${PROTOBUF_VER}/src
make -j$((NPROC*2))
strip src/sexcoin-cli.exe
strip src/sexcoind.exe
strip src/qt/sexcoin-qt.exe"
}

function init_SXC_vars() {
SXC=sexcoin
SXC_VER=0.6.4.6
SXC_URL=https://github.com/sxcer/sexcoin/archive/
SXC_SRC=build-with-.9deps.zip
SXC_MD5=86923a53f53f00c3799c100f81657608
SXC_UNPACKDIR=sexcoin-build-with-.9deps
SXC_MSYS2_BUILDCMDS="# sexcoin build commands
export PATH=\"${BASEDIR}/${QT_UNPACKDIR}/bin:$PATH\"
export QTDIR=${BASEDIR}/${QT_UNPACKDIR}
qmake \\
    USE_BUILD_INFO=1 USE_QRCODE=1 RELEASE=1 USE_UPNP=1 \\
    SRCDIR=/home/sxcer/src/sxc_winbuild/src \\
    BOOST_LIB_SUFFIX=-${BOOST_SUFFIX} \\
    BOOST_INCLUDE_PATH=${BASEDIR}/boost_${BOOST_VER} \\
    BOOST_LIB_PATH=${BASEDIR}/boost_${BOOST_VER}/stage/lib \\
    BDB_INCLUDE_PATH=${BASEDIR}/db-4.8.30.NC/build_unix \\
    BDB_LIB_PATH=${BASEDIR}/db-4.8.30.NC/build_unix/ \\
    BDB_LIB_SUFFIX=-4.8 \\
    OPENSSL_INCLUDE_PATH=${BASEDIR}/openssl-${OPENSSL_VER}/include \\
    OPENSSL_LIB_PATH=${BASEDIR}/openssl-${OPENSSL_VER} \\
    MINIUPNPC_INCLUDE_PATH=${BASEDIR} \\
    MINIUPNPC_LIB_PATH=${BASEDIR}/miniupnpc \\
    QRENCODE_INCLUDE_PATH=${BASEDIR}/qrencode-${QRENCODE_VER}/include \\
    QRENCODE_LIB_PATH=${BASEDIR}/qrencode-${QRENCODE_VER}/.libs \\
    QTDIR=${BASEDIR}/${QT_UNPACKDIR} \\
    sexcoin-qt.pro.windows
make || exit 1
strip release/sexcoin-qt.exe

#package up the binary with DLL deps

#packaging directory
pkgdir=sexcoin-qt-${SXC_VER}

#create packaging dir, wiping any existing packaging dir
[ -d \"release/\$pkgdir\" ] && rm -rf \"release/\$pkgdir\"
mkdir \"release/\$pkgdir\"

#wipe any exisiting packaged sexcoin-qt.exe
[ -f \"release/\${pkgdir}.zip\" ] && rm -rf \"release/\${pkgdir}.zip\"

#copy the exe
cp \"release/sexcoin-qt.exe\" \"release/\$pkgdir/\"

# find dll's exe requires
dlls=\$(ldd \"release/\${pkgdir}/sexcoin-qt.exe\" | \\
       awk '/mingw64/{print \$3}')

#copy the dlls to packaging dir
for dll in \$dlls ; do
    cp \"\$dll\" \"release/\$pkgdir/\" || exit 1
done

#\"package\" into a zip file
cd release/
zip -r sexcoin-qt-${SXC_VER}.zip \$pkgdir/
cd ..

echo \"sexcoin-qt.exe packaged in \$PWD/sexcoin-sexcoin-qt-${SXC_VER}.zip\"
"
}
#*****************************************************************************
# End Package Definition Functions
#*****************************************************************************


#*****************************************************************************
#
# General Functions
#
#*****************************************************************************
function check_shell() {
    if [ "$MSYSTEM"x == "MINGW64"x ] ; then
        return 0

    elif [ -z "$MSYSTEM" ] ; then
        echo "You do not appear to be in an msys2 shell."
        echo "The \$MSYSTEM environment variable does not exist."
        echo ""
        echo "Please exit and relaunch a shell with the:"
        echo "  C:\\msys64\\mingw64_shell.bat file"

    elif [ "$MSYSTEM"x == "MSYS"x ] ; then
        echo "\$MSYSTEM=\"${MSYSTEM}\""
        echo "You appear to be in the incorrect (msys2) shell."
        echo "Most likely you launched this shell from the:"
        echo "  C:\\msys64\\msys2_shell.bat file"
        echo ""
        echo "Please exit and relaunch a shell with the:"
        echo "  C:\\msys64\\mingw64_shell.bat file"

    elif [ "$MSYSTEM"x == "MINGW32"x ] ; then
        echo "\$MSYSTEM=\"${MSYSTEM}\""
        echo "You appear to be in the incorrect (mingw32) shell."
        echo "Most likely you launched this shell from the:"
        echo "  C:\\msys64\\mingw32_shell.bat file"
        echo ""
        echo "Please exit and relaunch a shell with the:"
        echo "  C:\\msys64\\mingw64_shell.bat file"
    else
        echo "\$MSYSTEM=\"${MSYSTEM}\""
        echo "Unable to identify the type of shell you are in."
        echo "Your \$MSYSTEM environment variable is set to a unrecognized value."
        echo ""
        echo "Please exit and relaunch a shell with the:"
        echo "  C:\\msys64\\mingw64_shell.bat file"

    fi

    return 1
}


function use_custom_basedir() {
    # Check if user set CUSTOM_BASEDIR and if we can use it
    # Return 0 if we are using it, 1 otherwise
    if [ "$CUSTOM_BASEDIR"x == "x" ] ; then
        return 1
    fi

    # Expand any ~ now or it will cause problems later
    eval CUSTOM_BASEDIR="$CUSTOM_BASEDIR"

    # check for whitespace in path
    if [ "${CUSTOM_BASEDIR/[:space:]}"x != "${CUSTOM_BASEDIR}"x ] ; then
        echo "Unable to use your CUSTOM_BASEDIR:"
        echo "   $CUSTOM_BASEDIR"
        echo "because it has a space in it which will cause build problems."
        return 1
    fi

    # go ahead and use it
    BASEDIR="$CUSTOM_BASEDIR"
    [ -d "$BASEDIR" ] || mkdir -p "$BASEDIR" || return 1
    echo "Using custom directory $BASEDIR"
}


function use_default_basedir() {
    # Use default basedir if it's ok
    local d="$(pwd)/src"

    # check for whitespace in path
    if [ "${d/([:space:])}"x != "${d}"x ] ; then
        echo "Unable to use your current working directory as default base dir:"
        echo "   $d"
        echo "It has a space which will cause problems with the build."
        return 1
    fi
    #no space, let it be used
    BASEDIR="$d"
    [ -d "$BASEDIR" ] || mkdir -p "$BASEDIR" || return 1
    echo "Using default directory: $BASEDIR"
}


function use_failsafe_basedir() {
    # using something that should be ok no matter what
    BASEDIR=/tmp/src
    [ -d "$BASEDIR" ] || mkdir -p "$BASEDIR" || return 1
    echo "Using failsafe directory: $BASEDIR"
}


function set_basedir() {
    if ! use_custom_basedir ; then
        if ! use_default_basedir ; then
            if ! use_failsafe_basedir ; then
                echo "Can't get usable base directory"
                exit 1
            fi
        fi
    fi
}


function check_toolchain() {
    echo -n "Checking for missing tools..."
    missing=$(pacman -Q $MSYS2_REQUIRED_PKGS 2>&1 | \
              awk '/package .* was not found/{print $3}' | sed "s/'//g" )
    if [ -n "$missing" ] ; then
        echo "Installing $missing ..."
        pacman -S $missing && echo "done." || return 1
    else
        echo "All Installed"
    fi
    echo -n "Checking path to gcc..."
    gcc -v >/dev/null 2>&1
    if  [ $? -ne 0 ] ; then
       echo "gcc not found, path contains:"
       echo "     $PATH"
       echo "     /mingw64/bin or /mingw32/bin should be first."
       echo "     Check for conflicting .profile or .bashrc in ~/"
       return 1
    else
       echo "OK"
    fi
    return 0
}


function mdfive() {
    # check MD5 sum of a file against expected MD5 sum
    # $1 = Filename(with path)
    # $2 = Expected MD5 sum
    # Returns 0 if sums match, 1 otherwise

    local temp=$(md5sum "$1")
    local  sum=${temp:0:32}

    echo "Expected MD5SUM:$2"
    echo "  Actual MD5SUM:$sum"

    [ "${sum}x" == "${2}x" ] && return 0

    echo "MD5 Check Failed for $1"
    return 1
}


function unpack() {
    # un{tar,zip,bzip,p7zip} a sourceball
    # Only handles the following extensions:
    # .tar .tar.gz .tgz tar.bz2 .zip .7z
    #
    # $1 = Filename(with path)
    # $2 = Unpack directory (wiped if present)
    # Returns 1 if file unpacks successfully, 0 otherwise

    local filename="${1}"
    local unpackpath="${BASEDIR}/$2"

    # skip unpack if the unpackdir contains .built file indicating
    # it's been built successfully
    if [ -f "${unpackpath}/.built" ] ; then
            echo "${unpackdir}/.built file present, skipping unpack"
            echo "If you really want to re-unpack, then run the clean command for this"
            echo "package or manually remove the file:"
            echo "   ${unpackpath}/.built"
            return 0
    fi

    # skip unpack if unpackdir already exists for this pkg
    # (you'll have to run clean for it)
    if [ -d "$unpackpath" ] ; then
        echo "Not touching existing unpackdir:"
        echo "$unpackpath"
        return 0
        #/bin/rm -rf "$unpackpath"
    fi

    # Get final extension ( from the end back to rightmost . )
    final_ext="${filename##*.}"

    # Strip that off $filename
    temp="${filename%.*}"

    # Inner extension ( or garbage if only single extension exists)
    inner_ext="${temp##*.}"

    case "$final_ext" in
        gz)
            if [ "${inner_ext}x" == "tarx" ] ; then
                tar -zxvf "$filename"
            else
                echo ".gz extension without.tar on $1"
                return 1
            fi
            ;;
        bz2|bzip2)
            if [ "${inner_ext}x" == "tarx" ] ; then
                tar -jxvf "$filename"
            else
                echo ".bz2 or .bzip2 extension without.tar on $1"
                return 1
            fi
            ;;
        xz)
            if [ "${inner_ext}x" == "tarx" ] ; then
                tar -Jxvf "$filename"
            else
                echo ".xz extension without.tar on $1"
                return 1
            fi
            ;;
        tar)
            tar -xvf "$filename"
            ;;
        zip)
            unzip "$filename"
            ;;
        p7z|7z)
            p7zip -d "$filename"
            ;;
        *)
            echo "Unknown extension on $1"
            return 1
            ;;
    esac

    # Return the exit code of the last cmd to run, which was
    # tar, unzip, p7zip etc from case statement above.
    return
}


function download_is_cached() {
    # checks $CACHEDIR to see if a download is already locally present
    # $1 = Download filename (no path)
    # Returns 0 if file is present
    # Returns 1 otherwise

    if [ -f "${CACHEDIR}/${1}" ] ; then
        echo "Using cached copy:"
        echo "${CACHEDIR}/$1"
        return 0
    fi
    return 1
}


function download() {
    # Download a file from URL (if not present in local "cache"), optionally
    # check MD5 sum on download or local "cached" file.
    # $1 = Complete download URL
    # $2 = Filename (without path, eg. myproject-1.0.tar.gz )
    # $3 = Optional MD5 sum (checked if present)
    #
    # Returns:
    # 0 If MD5 sum is NOT passed, file present in "cache", copy to $dest
    # 0 If MD5 sum is NOT passed, file download success, copy to $dest
    # 0 If MD5 sum passed, file present in "cache", MD5 sum OK, copy to $dest
    # 0 If MD5 sum passed, file download success, MD5 sum OK, copy to $dest
    # 1 Otherwise (MD5 mismatch, download fails, or copy to $dest fails)

    local dest="${BASEDIR}/$2"
    local cache="${CACHEDIR}/$2"
    local md5="$3"

    #Delete $dest if present
    if [ -f "$dest" ] ; then
        echo "Removing existing file: $dest"
        rm -f "$dest" >/dev/null 2>&1
    fi

    # If the file is in the cache and we have an expected MD5, check it
    if  download_is_cached "$2" ; then
        #If we have an expected MD5, check it
        if [ -n "$md5" ] ; then
            if mdfive "$cache"  $md5 ; then
                # just copy to dest
                /bin/cp -f "$cache" "$dest" && return 0
            else
                # cache file has invalid md5, delete
                /bin/rm -f "$cache"
            fi
        else
            # File is in cache, we dont' have expected MD5 so consider it OK
            # and copy to $dest and return
            /bin/cp -f "$cache" "$dest" && return 0
        fi
    fi

    # Download wasn't cached, or was cached but MD5 did not match
    wget --no-check-certificate -t3 --timeout=15 "$1" -O "$cache" || return 1

    #If we have an expected MD5
    if [ -n "$md5" ] ; then
        if mdfive "$cache" "$md5" ; then
            #MD5 good, keep copy the file over and return good
            echo "Copy cached file to:"
            echo "$dest"
            /bin/cp -f "$cache" "$dest" && return 0
        else
            #MD5 verification failed, delete file from cache
            rm -f "$cache"
            echo "Deleted $cache"
            return 1
        fi
    else
        #We dont' have an expected MD5 so we must consider it OK
        echo "Copy cached file to:"
        echo "$dest"
        /bin/cp -f "$cache" "$dest" && return 0
    fi

    #can't get here so return 1 if we do
    return 1
}


function clean() {
    local pkg=""

    cd "${BASEDIR}"
    for pkg in $PKGS ; do
        eval local name=\${$pkg}
        eval local src=\${${pkg}_SRC}
        eval local unpackdir=\${${pkg}_UNPACKDIR:=${name}-\${${pkg}_VER}}
        echo -n "Cleaning $pkg ..."
        /bin/rm -rf "$unpackdir" "$src" "${name}.buildcmds" && \
            echo "done." || exit 1
    done
}


function buildcmds() {
    local pkg=""

    for pkg in $* ; do
        eval local name=\${${pkg}}
        eval local buildcmds=\${${pkg}_MSYS2_BUILDCMDS}
        local filename=${BASEDIR}/${name}.buildcmds
        echo -n "Writing ${filename} ..."
        echo "$buildcmds" > ${filename}
        echo "done."
    done
}


function download_pkgs() {
    local pkg=""

    for pkg in $PKGS ; do
        eval local name=\${${pkg}}
        eval local url=\${${pkg}_URL}/\${${pkg}_SRC}
        eval local src=\${${pkg}_SRC}
        eval local md5=\${${pkg}_MD5}
        download "$url" "$src" "$md5" || exit 1
    done
}


function unpack_pkgs() {
    local pkg=""

    for pkg in $PKGS ; do
        eval local name=\${${pkg}}
        eval local url=\${${pkg}_URL}/\${${pkg}_SRC}
        eval local src=\${${pkg}_SRC}
        eval local md5=\${${pkg}_MD5}
        eval local unpackdir=\${${pkg}_UNPACKDIR:=${name}-\${${pkg}_VER}}

        # if we don't have the sourceball, get it
        [ -f "${BASEDIR}/$src" ] || download_pkgs "$pkg" || exit 1

        unpack "$src" "$unpackdir" || exit 1
    done
}


function build_pkgs() {
    local pkg=""

    for pkg in $PKGS ; do
        eval local name=\${${pkg}}
        eval local url=\${${pkg}_URL}/\${${pkg}_SRC}
        eval local src=\${${pkg}_SRC}
        eval local md5=\${${pkg}_MD5}
        eval local unpackdir=\${${pkg}_UNPACKDIR:=${name}-\${${pkg}_VER}}
        eval local msys2_buildcmds=\${${pkg}_MSYS2_BUILDCMDS}

        # if we don't have the sourceball, get it
        [ -f "${BASEDIR}/$src" ] || download_pkgs "$pkg" || exit 1

        # Assume any unpacked dir present is ok
        [ -d "${BASEDIR}/$unpackdir" ] || \
             unpack "$src" "$unpackdir" || exit 1

        #build if it's not marked "built"
        if [ -f "${BASEDIR}/${unpackdir}/.built" ] ; then
            echo "${unpackdir}/.built file present, skipping build"
        else
            echo "Building $name in:"
            echo "${BASEDIR}/$unpackdir"
            echo "with the following cmds:"
            echo "$msys2_buildcmds"
            buildcmds $pkg
            cd "${BASEDIR}/$unpackdir"
            eval "$msys2_buildcmds"
            if [ "$?" -eq 0 ] ; then
                touch "${BASEDIR}/${unpackdir}/.built"
            else
               # quit building here so user can see packge didn't build
               echo "$pkg build failed."
               cd "$BASEDIR"
               return 1
            fi
            cd "$BASEDIR"
        fi
    done
}


function status_pkgs() {
    local pkg=''
    for pkg in $* ; do
        eval local name=\${${pkg}}
        eval local url=\${${pkg}_URL}/\${${pkg}_SRC}
        eval local src=\${${pkg}_SRC}
        eval local md5=\${${pkg}_MD5}
        eval local unpackdir=\${${pkg}_UNPACKDIR:=${name}-\${${pkg}_VER}}
        echo -e "\n\n*************************"
        printf %25s\\n $name
        echo -e "*************************"
        echo -n "   URL Check: "
        wget -q --spider $url
        if [ $? -eq 0 ] ; then
             echo "Success"
        else
             echo "Failed"
        fi

        echo -n "      Cached: "
        if [ -f "$CACHEDIR/$src" ] ; then
             echo "Yes"
             echo -n "     MD5 Sum: "
             local temp=$(md5sum "$CACHEDIR/$src")
             local  sum=${temp:0:32}
             if [ "${sum}"x == "${md5}"x ] ; then
                 echo "Good"
             else
                 echo "Bad"
             fi
        else
             echo "No"
        fi

        echo -n "  Unpack Dir: "
        if [ -d "$BASEDIR/$unpackdir" ] ; then
             echo "Present"
        else
            echo "Not Present"
        fi
        
        echo -n "Marked Built: "
        if [ -f "$BASEDIR/$unpackdir/.built" ] ; then
             echo "Yes"
        else
             echo "No"
        fi

    done
}


function init_pkg_args() {
    # $1 through $n passed direclty to this script should be list of packages
    #
    # This script will populate $PKGS with a dedup'd list of packages to build
    # which includes all valid packages passed as args plus their dependencies.
    #
    # It will also call all init_<PKG>_vars() functions so basically, after
    # this script runs, calling build_pkgs() or clean() will be able to 
    # operate on the list of packages in PKGS and make use of all <PKG>_xxxx
    # variables
    #
    # Return TRUE if one or more valid pkg arguments are passed and no errors
    # are encountered.
    # Returns FALSE otherwise
    #

    local args=''
    local arg=''
    DEPS=''
    PKGS=''

    # If no args are passed, error out
    if [ "$#" -eq 0 ] ; then
        echo "No package(s) specified."
        echo "Run \"$0 pkgs\" to see a list of packages"
        return 1
    fi

    args="$*"

    for arg in $args ; do
        if valid_pkg "$arg" ; then
            DEPS=''
            get_deps "$arg" || return 1
            append_to_PKGS "$DEPS"
            DEPS=''
        else
            echo "$arg is not a valid PKG, run $0 pkgs to see valid PKGs"
            return 1
        fi
    done

    dedup_PKGS
    echo "Final PKG list including DEPS:"
    echo "      $PKGS"
    return 0
}


function dedup_PKGS() {
    local pkg=''
    local newpkg=''
    local newpkgs=''

    for pkg in $PKGS ; do
        for newpkg in $newpkgs ; do
            if [ "$pkg"x == "$newpkg"x ] ; then
                continue 2
            fi
        done

        if [ "$newpkgs"x == ""x ] ; then
            newpkgs="$pkg"
        else

            newpkgs+=" $pkg"
        fi
    done

    PKGS="$newpkgs"
}


function append_to_PKGS() {
    while [ "$#" -gt 0 ] ; do
        if [ "$PKGS"x == ""x ] ; then
            PKGS="$1"
        else
            PKGS+=" $1"
        fi
        shift 1
    done
}


function append_to_DEPS() {
    while [ "$#" -gt 0 ] ; do
        if [ "$DEPS"x == ""x ] ; then
            DEPS="$1"
        else
            DEPS+=" $1"
        fi
        shift 1
    done
}


function valid_pkg() {
    local pkg=''
    for pkg in $MASTERPKGLIST ; do
        [ "$1"x == "$pkg"x ] && return 0
    done
    return 1
}


function get_deps() {
    local  pkgdep=''
    local pkgdeps=''

    #get the deps for this package (which are defined outside
    # the package var init function)
    eval pkgdeps=\"\$$1_DEPS\"

    if [ -n "$pkgdeps" ] ; then
        #iterate and recurse on pkgdeps 
        for pkgdep in $pkgdeps ; do
           if valid_pkg $pkgdep ; then
               get_deps $pkgdep;
           else
               return 0
           fi
        done
    fi

    # at this point, this package has all
    # it's dependency package's vars init'd 
    # so initialize this package's vars and
    # append it to the DEPS
    eval init_${1}_vars
    append_to_DEPS "$1"
    return 0
}


function usage() {
    echo "  Usage: $0 [SUBCMD] [PKG]..."
    echo ""
    echo "  SUBCMD is one of:"
    echo "          pkgs  Lists all valid PKG names this script understands"
    echo "         build  Build (download/unpack if needed) [PKG]..."
    echo "      buildall  Build (download/unpack if needed) all packages"
    echo "         clean  Remove package files/dirs for [PKG]..."
    echo "      cleanall  Remove package files/dirs for all packages"
    echo "      download  Download source for [PKG}..."
    echo "   downloadall  Download source for all packages"
    echo "        unpack  Unpack(download if needed) [PKG]..."
    echo "     unpackall  Unpack(download if needed) all packages"
    echo "     buildcmds  Write build cmds for [PKG]... to PKGNAME.buildcmds"
    echo "  buildcmdsall  Write build cmds for all packages to PKGNAME.buildcmds"
    echo "          pkgs  List all valid PKG names this script understands"
    echo "          deps  List dependency packages for [PKG]... "
    echo "          dirs  Print BASEDIR and CACHEDIR being used"
    echo "          help  This help message"
    echo ""
}
#*****************************************************************************
# End of Functions
#*****************************************************************************


#*****************************************************************************
#
# Main Execution start
#
#*****************************************************************************
SUBCOMMANDS="clean cleanall buildcmds buildcmdsall pkgs download downloadall \ 
             unpack unpackall build buildall deps dirs status statusall help"

# Make this available for use for in buildcmds with make and mingw32-make
# -j option. (can break the make, so I removed -j's from some buildcmds)
NPROC=$(/usr/bin/nproc)

# Toolchain/tools packages and check/install function
MSYS2_REQUIRED_PKGS="git wget diffutils p7zip unzip automake-wrapper autoconf \
                     tar libtool mingw-w64-x86_64-gcc make pkg-config \
                     mingw-w64-x86_64-make"

set_basedir && cd "$BASEDIR" || exit 1

# Directory used to store a copy of downloaded source packages. They are
# not deleted during a "clean up" run of this script.
CACHEDIR=${BASEDIR}/.download_cache
[ -d "$CACHEDIR" ] || mkdir -p "$CACHEDIR"

# Handle no subcommand and invalid subcommand
if [ "$#" -lt 1 ] ; then
    echo -e "No subcommand given\n"
    usage
    exit 1
fi
if [ "${SUBCOMMANDS/$1}" == "$SUBCOMMANDS" ] ; then
    echo -e "Invalid subcommand\n"
    usage
    exit 1
fi

# Handle subcommands that don't require toolchain check
case $1 in
    help)
        usage
        exit 0
        ;;
    dirs)
        echo " BASEDIR=${BASEDIR}"
        echo "CACHEDIR=${CACHEDIR}"
        exit 0
        ;;
    pkgs)
        echo -e "Aware of the following packages:\n$MASTERPKGLIST"
        exit 0
        ;;
esac

# Check the shell before toolchain
# There's three "start a shell" .bat files in c:\msys64 but we need to be in
# one started from mingw64_shell.bat
# (We really only need the $MSYS=MINGW64 environment var it sets, I think)
check_shell || exit 1

# Check that toolchain is present and working before
# handling remaining subcommands
check_toolchain || exit 1

# Handle remaining subcommands
case $1 in
    clean)
        shift 1
        init_pkg_args $* && clean
        exit
        ;;
    cleanall)
        init_pkg_args $MASTERPKGLIST && clean
        exit
        ;;
    buildcmds)
        shift 1
        init_pkg_args $* && buildcmds $*
        exit
        ;;
    buildcmdsall)
        init_pkg_args $MASTERPKGLIST && buildcmds $MASTERPKGLIST
        exit
        ;;
    download)
        shift 1
        init_pkg_args $* && download_pkgs
        exit
        ;;
    downloadall)
        init_pkg_args $MASTERPKGLIST && download_pkgs
        exit
        ;;
    unpack)
        shift 1
        init_pkg_args $* && unpack_pkgs
        exit
        ;;
    unpackall)
        init_pkg_args $MASTERPKGLIST && unpack_pkgs
        exit
        ;;
    build)
        shift 1
        init_pkg_args $* && build_pkgs
        exit
        ;;
    buildall)
        init_pkg_args $MASTERPKGLIST && build_pkgs
        exit
        ;;
    deps)
        shift 1
        init_pkg_args $*
        exit
        ;;
    status)
        shift 1
        init_pkg_args $* && status_pkgs $*
        ;;
    statusall)
        init_pkg_args $MASTERPKGLIST && status_pkgs $MASTERPKGLIST
        ;;
    *)
        echo -e "Unknown command/option given\n"
        usage
    exit 1
    ;;
esac
