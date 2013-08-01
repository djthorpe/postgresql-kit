#!/bin/bash

# Make openssl from source, and create a symbolic link
# to the compiled package.
#
# Syntax:
#   make-openssl.sh (input_tar) (output_directory) (flags)
#
# Flags:
#   --clean will always rebuild from clean sources
#   --platform=<platform> will built for one of these
#      architectures:
#         mac_x86_64 ios_armv7 ios_armv7s ios_simulator

##############################################################
# Process command line arguments

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UNARCHIVE=${DERIVED_SOURCES_DIR}
TARZ=${1}
BUILD=${2}
CLEAN=0
PLATFORM=mac_x86_64

for ARG in "$@"
do
    case ${ARG} in
	  --clean )
	    CLEAN=1
		;;
	  --platform=* )
	    PLATFORM=`echo ${ARG} | sed 's/[-a-zA-Z0-9]*=//'`
        ;;
	esac
done

##############################################################
# Sanity checks

# Check for the TAR file to make sure it exists
if [ "${#}" == "0" ] || [ "${TARZ}" == "" ] || [ ! -e "${TARZ}" ]
then
  echo "Syntax error: make-openssl.sh {INPUT_TAR_GZ} {OUTPUT_FOLDER} (--clean) (--platform=mac_x86_64|ios_armv7|ios_armv7s|ios_simulator)"
  exit 1
fi

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
if [ "${UNARCHIVE}" == "" ]
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

DEVELOPER_PATH=`xcode-select --print-path`
MACOSX_DEPLOYMENT_TARGET=10.7
IPHONE_DEPLOYMENT_TARGET=6.1

case ${PLATFORM} in
  mac_x86_64 )
    ARCH="x86_64"
    DEVROOT="${DEVELOPER_PATH}/Platforms/MacOSX.platform/Developer"
	SDKROOT="${DEVROOT}/SDKs/MacOSX${MACOSX_DEPLOYMENT_TARGET}.sdk"
	CC="/usr/bin/gcc -arch ${ARCH}"
	CONFIGURE_FLAGS="darwin64-x86_64-cc no-shared no-krb5 no-zlib"
	;;
  ios_armv7 )
    ARCH="armv7"
    DEVROOT="${DEVELOPER_PATH}/Platforms/iPhoneOS.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/iPhoneOS${IPHONE_DEPLOYMENT_TARGET}.sdk"
    CC="${DEVROOT}/usr/bin/gcc -arch ${ARCH}"
    CONFIGURE_FLAGS="iphoneos-cross no-shared no-asm no-krb5 no-zlib"
    ;;
  ios_armv7s )
    ARCH="armv7s"
    DEVROOT="${DEVELOPER_PATH}/Platforms/iPhoneOS.platform/Developer"
	SDKROOT="${DEVROOT}/SDKs/iPhoneOS${IPHONE_DEPLOYMENT_TARGET}.sdk"
    CC="${DEVROOT}/usr/bin/gcc -arch ${ARCH}"
    CONFIGURE_FLAGS="iphoneos-cross no-shared no-asm no-krb5 no-zlib"
    ;;
  ios_simulator )
    ARCH="i386"
    DEVROOT="${DEVELOPER_PATH}/Platforms/iPhoneSimulator.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/iPhoneSimulator${IPHONE_DEPLOYMENT_TARGET}.sdk"
    CC="${DEVROOT}/usr/bin/gcc -arch ${ARCH}"
    CONFIGURE_FLAGS="iphoneos-cross no-shared no-asm no-krb5 no-zlib"
	;;
  * )
    echo "Unknown build platform: ${PLATFORM}"
	exit -1
esac

CFLAGS="-isysroot ${SDKROOT} ${DEPLOYMENT_TARGET}"

##############################################################
# Check to see if already built, ignore if so

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
echo "Architecture: ${ARCH}"
echo "       Flags: ${CONFIGURE_FLAGS}"

cd "${UNARCHIVE}/${VERSION}"
./Configure ${CONFIGURE_FLAGS} --prefix=${PREFIX}
make CC="${CC}" CFLAG="${CFLAGS}"
make install_sw >/dev/null

##############################################################
# Make symbolic links

rm -f ${BUILD}/openssl-current-${PLATFORM}
ln -s ${PREFIX} ${BUILD}/openssl-current-${PLATFORM}

exit 0


