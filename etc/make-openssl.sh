#!/bin/bash

# Make openssl from source in the tar subdirectory
# Syntax:
#   make-openssl.sh ${INPUT_TAR} ${OUTPUT_DIR}

CLEAN=0
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UNARCHIVE=${DERIVED_SOURCES_DIR}
TARZ=${1}
BUILD=${2}
PLATFORM=ios_armv7

# Check for the TAR file to make sure it exists
if [ "${#}" == "0" ] || [ "${TARZ}" == "" ] || [ ! -e "${TARZ}" ]
then
	echo "Syntax error: make-openssl.sh {INPUT_TAR_GZ} {OUTPUT_FOLDER} (--clean)"
	exit 1
fi

##############################################################
# Check switches

for ARG in "$@"
do
    case ${ARG} in
        "--clean" )
           CLEAN=1
		   ;;
	esac
done

##############################################################
# Set version number

VERSION=`basename ${TARZ} | sed 's/\.tar\.gz//'`

# Check for the BUILD directory
if [ "${BUILD}XX" == "XX" ] || [ ! -d ${BUILD} ]
then
    echo "Syntax error: make-openssl.sh {INPUT_TAR_GZ} {OUTPUT_FOLDER}"
    exit 1
fi

# Check for the UNARCHIVE  directories, use TMP if necessary
if [ "${UNARCHIVE}XX" == "XX" ]
then
	UNARCHIVE=${TMPDIR}/${VERSION}/src
fi
if [ ! -d ${UNARCHIVE} ]
then
	echo "mkdir ${UNARCHIVE}"
	mkdir -pv ${UNARCHIVE}
fi

##############################################################
# remove existing build directory, unarchive

rm -fr "${UNARCHIVE}"
mkdir "${UNARCHIVE}"
tar -C ${UNARCHIVE} -zxf ${TARZ}

##############################################################
# Architectures

case ${PLATFORM} in
  x86_64 )
    ARCH="darwin64-x86_64-cc"
    SDKROOT="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform"
    CONFIGURE_FLAGS="noshared --without-readline"
	;;
  ios_armv7 )
    ARCH="BSD-generic32"
	DEVROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/iPhoneOS6.0.sdk"
    CONFIGURE_FLAGS=""
    export CPPFLAGS="-I$SDKROOT/usr/lib/gcc/i686-apple-darwin10/4.2.1/include/ -I$SDKROOT/usr/llvm-gcc-4.2/lib/gcc/i686-apple-darwin10/4.2.1/include/ -I$SDKROOT/usr/include/ -I$SDKROOT/usr/include/c++/4.2.1/armv7-apple-darwin10/ -miphoneos-version-min=2.0"
	export CFLAGS="$CPPFLAGS -pipe -no-cpp-precomp -isysroot $SDKROOT"
	export CPP="$DEVROOT/usr/bin/cpp $CPPFLAGS"
	export CXXFLAGS="$CFLAGS"
	export LDFLAGS="-L$SDKROOT/usr/lib/ -isysroot $SDKROOT -Wl,-dead_strip -miphoneos-version-min=2.0"
	;;
  ios_i386 )
    ARCH="i386-apple-darwin"
    SDKROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.0.sdk"
    CONFIGURE_FLAGS="--without-readline --disable-ipv6"
	CC="$DEVROOT/usr/bin/gcc-4.2"
	LD="$DEVROOT/usr/bin/ld"
	;;
  * )
    echo "Unknown build platform: ${PLATFORM}"
	exit -1
esac

##############################################################
# Check to see if already built

PREFIX=${BUILD}/${VERSION}/${PLATFORM}

if [ -e ${PREFIX} ] && [ ${CLEAN} == 0 ]
then
  echo "Assuming already exists: ${PREFIX}"
  exit 0
fi

##############################################################
# Building

echo "Derived data: ${UNARCHIVE}"
echo "    Build to: ${PREFIX}"
echo "Architecture: ${PLATFORM}"

echo "       Flags: ${CONFIGURE_FLAGS} --prefix=${PREFIX} ${ARCH}"

cd "${UNARCHIVE}/${VERSION}"
./Configure ${ARCH} ${CONFIGURE_FLAGS} --prefix=${PREFIX}

perl -i -pe 's|static volatile sig_atomic_t intr_signal|static volatile int intr_signal|' crypto/ui/ui_openssl.c
perl -i -pe "s|^CC= gcc|CC= ${GCC} -arch ${ARCH}|g" Makefile
perl -i -pe "s|^CFLAG= (.*)|CFLAG= -isysroot ${SDK} \$1|g" Makefile

make && make install

##############################################################
# Make symbolic links

rm -f ${BUILD}/openssl-current-${PLATFORM}
ln -s ${PREFIX} ${BUILD}/openssl-current-${PLATFORM}

exit 0


