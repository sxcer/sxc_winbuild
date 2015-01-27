#/bin/sh
# sxc_winbuild.sh v0.5 - Automated building of sexcoin-qt (and dependencies)
#                        on Windows using msys2
# https://github.com/sxcer/sxc_winbuild                     sxcerr@gmail.com
#
# See README here:
# https://github.com/sxcer/sxc_winbuild/blob/master/README.md
#
# Run this script from an msys2 shell with no args to build sexcoin-qt.exe
# Run "sxc_winbuild.sh help" to see options
#
#                  *msys2 Is Required (not msys)*
# Installation of msys2 x86_64 to the default c:\msys64 directory
# is described here:
#          http://msys2.github.io/
#
# Double-click c:\mingw64\mingw64_shell.bat and type:
#     pacman -Sy
#     pacman -S wget
#     wget https://github.com/sxcer/sxc_winbuild/raw/master/sxc_winbuild.sh
#     sh sxc_winbuild.sh
#
# It will take a long while to download all packages and build (including
# building Qt5 from source) so be prepared to wait.

# By default this script will use "src/" in your msys2 home dir (~/src ).
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
CUSTOM_BASEDIR=
#CUSTOM_BASEDIR=/c/src
#CUSTOM_BASEDIR=/c/Users/jsmith/src
#CUSTOM_BASEDIR=/x/src


##########################################################################
# Below here, you should know a little about what you are doing to edit.
##########################################################################

# This would use the current dir as the base dir.... I assume there will be
# problems running from directories/paths with spaces (untested)
#BASEDIR=${USER_BASEDIR:="$(/bin/pwd)"}

# Default BASEDIR setting
BASEDIR=${USER_BASEDIR:="~/src"}

# Directory used to store a copy of downloaded source packages. They are
# not deleted during a "clean up" run of this script.
CACHEDIR=${BASEDIR}/.download_cache

# Make this available for use for in buildcmds with make and mingw32-make
# -j option. (tends to break the make, so I removed -j's from some buildcmds)
NPROC=$(/usr/bin/nproc)

# Toolchain/tools packages and check/install function
MSYS2_REQUIRED_PKGS="git wget diffutils p7zip tar unzip automake-wrapper autoconf \
                     libtool mingw-w64-x86_64-gcc make pkg-config \
                     mingw-w64-x86_64-make"
function check_toolchain() {
    missing=$(pacman -Q $MSYS2_REQUIRED_PKGS 2>&1 | awk '/package .* was not found/{print $3}' | sed "s/'//g" )
    if [ -n "$missing" ] ; then
        echo "Installing $missing ..."
        pacman -S $missing && echo "done." || exit 1
    fi

    gcc -v >/dev/null 2>&1
    if  [ $? -ne 0 ] ; then
       echo "gcc not found, path contains:"
       echo "$PATH"
       echo "/mingw64/bin or /mingw32/bin should be first."
       echo "Check for conflicting .profile or .bashrc in ~/"
       exit 1
    fi

}
# need to check toolchain early because gcc version is retrieved during
# setting of BOOST_SUFFIX var.
if check_toolchain ; then
    TOOLCHAIN_OK=0
else
    TOOLCHAIN_OK=1
fi

# Dependency packages to build.
# These are packages *generally* required by the buildprocess of *coin
# Built in left to right order, consider dependencies when modifying.
#
# If you don't want a gui client, I assume you could remove QT and QTTOOLS to
# save quite a bit of build time(untested). *coin configure scripts seem to
# skip GUI build if they can't find Qt.
DEPS="OPENSSL BDB BOOST MINIUPNPC PROTOBUF LIBPNG QRENCODE QT QTTOOLS"

# Add DEPS to PKGS list
PKGS="$DEPS"

# Build sexcoin
PKGS+=" SXCNG"

# Build bitcoin
#PKGS+=" BTC"

##############################################################################
#
# Package Definitions
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
OPENSSL=openssl
OPENSSL_VER=1.0.1l
OPENSSL_URL=http://www.openssl.org/source
OPENSSL_SRC=${OPENSSL}-${OPENSSL_VER}.tar.gz
OPENSSL_MD5=cdb22925fc9bc97ccbf1e007661f2aa6
OPENSSL_MSYS2_BUILDCMDS="# openssl build commands
+./Configure no-zlib no-shared no-dso no-krb5 no-camellia no-capieng no-cast no-cms no-dtls1 no-gost no-gmp no-heartbeats no-idea no-jpake no-md2 no-mdc2 no-rc5 no-rdrand no-rfc3779 no-rsax no-sctp no-seed no-sha0 no-static_engine no-whirlpool no-rc2 no-rc4 no-ssl2 no-ssl3 mingw64
./Configure no-shared no-dso mingw64

make"


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
make"


BOOST=boost
BOOST_VER=1_55_0
BOOST_URL=http://sourceforge.net/projects/boost/files/boost/1.55.0
BOOST_SRC=${BOOST}_${BOOST_VER}.7z
BOOST_MD5=4e5bbc15fc8c80df8be428f8a5b5a823
BOOST_UNPACKDIR="${BOOST}_${BOOST_VER}"
GCC_VER_TOKEN=$(/mingw64/bin/gcc -v 2>&1 | \
                awk '/gcc version/{print $3}' | \
                awk -F. '{print $1 $2}')
BOOST_SUFFIX=mgw${GCC_VER_TOKEN}-mt-s-${BOOST_VER%%_0}
BOOST_MSYS2_BUILDCMDS="# boost build commands
./bootstrap.bat mingw
./b2 \\
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


MINIUPNPC=miniupnpc
MINIUPNPC_VER=1.9
MINIUPNPC_URL=http://miniupnp.free.fr/files
MINIUPNPC_SRC=${MINIUPNPC}-${MINIUPNPC_VER}.tar.gz
MINIUPNPC_MD5=5ef3ba321e6df72d6519b728b292073e
MINIUPNPC_MSYS2_BUILDCMDS="# miniupnpc build commands
mingw32-make.exe  -f Makefile.mingw init upnpc-static"


PROTOBUF=protobuf
PROTOBUF_VER=2.5.0
PROTOBUF_URL=http://protobuf.googlecode.com/files
PROTOBUF_SRC=${PROTOBUF}-${PROTOBUF_VER}.zip
PROTOBUF_MD5=2394c001bdb33f57efbcdd436bf12c83
PROTOBUF_MSYS2_BUILDCMDS="# protobuf build commands
./configure --disable-shared
make"


LIBPNG=libpng
LIBPNG_VER=1.6.12
LIBPNG_SRC=${LIBPNG}-${LIBPNG_VER}.tar.gz
LIBPNG_MD5=297388a6746a65a2127ecdeb1c6e5c82
LIBPNG_URL=http://prdownloads.sourceforge.net/libpng
LIBPNG_MSYS2_BUILDCMDS="# libpng build commands
./configure --disable-shared
make
cp ./.libs/libpng16.a ./.libs/libpng.a"


QRENCODE=qrencode
QRENCODE_VER=3.4.4
QRENCODE_SRC=${QRENCODE}-${QRENCODE_VER}.tar.gz
QRENCODE_MD5=be545f3ce36ea8fbb58612d72c4222de
QRENCODE_URL=http://fukuchi.org/works/qrencode
QRENCODE_MSYS2_BUILDCMDS="# qrencode build commands
      LIBS='../libpng-1.6.12/.libs/libpng.a /mingw64/lib/libz.a' \\
png_CFLAGS='-I../libpng-1.6.12' \\
  png_LIBS='-L../libpng-1.6.12/.libs'  \\
./configure --enable-static --disable-shared --without-tools
make"


QT=qtbase
QT_VER=5.3.1
QT_SRC=qtbase-opensource-src-${QT_VER}.7z
QT_MD5=ed0b47dbb77d4aa13e65a8a25c6e8e04
QT_URL=http://download.qt-project.org/official_releases/qt/5.3/5.3.1/submodules
QT_UNPACKDIR=qtbase-opensource-src-5.3.1
QT_MSYS2_BUILDCMDS="# qtbase build commands
mingw32-make confclean
./configure.exe  -I ${BASEDIR}/libpng-1.6.12 \\
                 -I ${BASEDIR}/openssl-${OPENSSL_VER}/include \\
                 -L ${BASEDIR}/libpng-1.6.12/.libs \\
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
mingw32-make"


QTTOOLS=qttools
QTTOOLS_VER=5.3.1
QTTOOLS_SRC=qttools-opensource-src-${QT_VER}.7z
QTTOOLS_MD5=8cce6f38f3d59cad495aed0c0eab8cea
QTTOOLS_URL=http://download.qt-project.org/official_releases/qt/5.3/5.3.1/submodules
QTTOOLS_UNPACKDIR=qttools-opensource-src-5.3.1
QTTOOLS_MSYS2_BUILDCMDS="# qttools build commands
export PATH=\"$PATH:${BASEDIR}/${QT_UNPACKDIR}/bin\"
qmake.exe qttools.pro
mingw32-make"


BTC=bitcoin
BTC_VER=0.9.2.1
BTC_SRC=v0.9.2.1.zip
BTC_MD5=
BTC_URL=https://github.com/bitcoin/bitcoin/archive
BOOST_SUFFIX=mgw49-mt-s-${BOOST_VER%%_0}
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
    -L${BASEDIR}/miniupnpc \\
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
make
strip src/bitcoin-cli.exe
strip src/bitcoind.exe
strip src/qt/bitcoin-qt.exe"


SXCNG=sexcoin-ng
SXCNG_VER=master
SXCNG_SRC=master.zip
SXCNG_MD5=
SXCNG_URL=https://github.com/sxcer/sexcoin-ng/archive
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
    -L${BASEDIR}/miniupnpc \\
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
make
strip src/sexcoin-cli.exe
strip src/sexcoind.exe
strip src/qt/sexcoin-qt.exe"


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

    # remove any existing unpackdir for this pkg
    if [ -d "$unpackpath" ] ; then
        echo "Removing existing unpackdir:"
        echo "$unpackpath"
        /bin/rm -rf "$unpackpath"
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
            if mdfive $cache  $md5 ; then
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
    local pkgs=""

    # If arg1 present, consider all args a pkg
    # otherwise, do all packages
    [ "$#" -gt 0 ] && pkgs="$*" || pkgs="$PKGS"

    cd "${BASEDIR}"
    for pkg in $pkgs ; do
        eval local name=\${$pkg}
        eval local src=\${${pkg}_SRC}
        eval local unpackdir=\${${pkg}_UNPACKDIR:=${name}-\${${pkg}_VER}}
        echo -n "Cleaning $pkg ..."
        /bin/rm -rf "$unpackdir" "$src" "${name}.buildcmds" "${CACHEDIR}/${src}" && \
            echo "done." || exit 1
    done
}

function buildcmds() {
    local pkg=""
    local pkgs=""

    # If arg1 present, consider all args a pkg
    # otherwise, do all packages
    [ "$#" -gt 0 ] && pkgs="$*" || pkgs=$PKGS

    for pkg in $pkgs ; do
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
    local pkgs=""

    # If arg1 present, consider all args a pkg
    # otherwise, do all packages
    [ "$#" -gt 0 ] && pkgs="$*" || pkgs=$PKGS

    for pkg in $pkgs ; do
        eval local name=\${${pkg}}
        eval local url=\${${pkg}_URL}/\${${pkg}_SRC}
        eval local src=\${${pkg}_SRC}
        eval local md5=\${${pkg}_MD5}
        download "$url" "$src" "$md5" || exit 1
    done
}

function unpack_pkgs() {
    local pkg=""
    local pkgs=""

    # If arg1 present, consider all args a pkg
    # otherwise, do all packages
    [ "$#" -gt 0 ] && pkgs="$*" || pkgs=$PKGS

    for pkg in $pkgs ; do
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
    local pkgs=""

    # If arg1 present, consider all args a pkg
    # otherwise, do all packages
    [ "$#" -gt 0 ] && pkgs="$*" || pkgs=$PKGS

    for pkg in $pkgs ; do
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

function check_pkg_args() {
    # Make sure any package args are for valid packages
    # $1 should be list of packages

    while [ -n "$1" ] ; do
        local pkg="$1"
        if [  "${PKGS/ $pkg }x" == "${PKGS}x" ] ; then
            echo "$pkg is not a valid PKG, run $0 pkgs to see valid PKGs"
            return 1
        fi
        shift 1
    done
    return 0
}

function usage() {
    echo "  Usage: $0 [CMD] [PKG]..."
    echo ""
    echo "  CMD is one of:"
    echo "         clean  Removes pkg files/dirs for all packages or [PKG]..."
    echo "          pkgs  Lists all valid PKG names this script understands"
    echo "      download  Downloads source for all packages or [PKG}..."
    echo "        unpack  Unpacks(downloads if necessary) all packages or [PKG]..."
    echo "     buildcmds  Write build commands for all packages to pkgname.buildcmds"
    echo "                or [PKG]..."
    echo "         build  Builds (downloads and unpacks if necessary) all packages or"
    echo "                [PKG]..."
    echo "          dirs  Print BASEDIR and CACHEDIR being used"
    echo "          help  This help message"
    echo ""
    echo "If no PKG arguments are present, all known packages assumed as targets"
}

# Create BASEDIR and CACHEDIR if needed
[ -d "$BASEDIR" ] || mkdir -p "$BASEDIR"
[ -d "$CACHEDIR" ] || mkdir -p "$CACHEDIR"

cd "$BASEDIR"

# If any args passed...
if [ "$#" -gt 0 ] ; then
    case $1 in
        clean)
            shift 1
            check_pkg_args $* && clean $*
            exit
            ;;
        buildcmds)
            shift 1
            check_pkg_args $* && buildcmds $*
            exit
            ;;
        pkgs)
            echo -e "Aware of the following packages:\n$PKGS"
            exit
            ;;
        toolchain)
            if [ "$TOOLCHAIN_OK" -eq 0 ] ; then
                echo "Toolchain/tools OK"
            else
                echo "Toolchain/tools error"
                exit
            fi
            ;;
        download)
            shift 1
            check_pkg_args $* && download_pkgs $*
            exit
            ;;
        unpack)
            shift 1
            check_pkg_args $* && unpack_pkgs $*
            exit
            ;;
        build)
            shift 1
            check_pkg_args $* && build_pkgs $*
            exit
            ;;
        dirs)
            echo " BASEDIR=${BASEDIR}"
            echo "CACHEDIR=${CACHEDIR}"
            ;;
        help|*)
            usage
            ;;
    esac
else
    echo -e "No command given\n"
    usage
fi
