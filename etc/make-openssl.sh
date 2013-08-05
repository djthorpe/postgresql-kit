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
UNARCHIVE="${DERIVED_SOURCES_DIR}"
TARZ="${1}"
BUILD="${2}"
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
if [ "${BUILD}XX" == "XX" ] || [ ! -d "${BUILD}" ]
then
    echo "Syntax error: make-openssl.sh {INPUT_TAR_GZ} {OUTPUT_FOLDER}"
    exit 1
fi

##############################################################
# Architectures

DEVELOPER_PATH=`xcode-select --print-path`
if [ ! -d "$DEVELOPER_PATH" ]; then
  echo "XCode not installed"
  exit -1
fi

MACOSX_DEPLOYMENT_TARGET=10.8
IPHONE_DEPLOYMENT_TARGET=6.1

case ${PLATFORM} in
  mac_x86_64 )
    ARCH="x86_64"
	export CROSS_TOP="${DEVELOPER_PATH}/Platforms/MacOSX.platform/Developer"
    export CROSS_SDK="MacOSX${MACOSX_DEPLOYMENT_TARGET}.sdk"
    export CC="/usr/bin/gcc -arch ${ARCH}"
	CONFIGURE_FLAGS="darwin64-x86_64-cc no-gost zlib"
	;;
  ios_armv7 )
    ARCH="armv7"
    export CROSS_TOP="${DEVELOPER_PATH}/Platforms/iPhoneOS.platform/Developer"
    export CROSS_SDK="iPhoneOS${IPHONE_DEPLOYMENT_TARGET}.sdk"
    export CC="${CROSS_TOP}/usr/bin/gcc -arch ${ARCH}"
    CONFIGURE_FLAGS="iphoneos-cross no-gost zlib"
    ;;
  ios_armv7s )
    ARCH="armv7s"
    export CROSS_TOP="${DEVELOPER_PATH}/Platforms/iPhoneOS.platform/Developer"
    export CROSS_SDK="iPhoneOS${IPHONE_DEPLOYMENT_TARGET}.sdk"
    export CC="${CROSS_TOP}/usr/bin/gcc -arch ${ARCH}"
    CONFIGURE_FLAGS="iphoneos-cross no-gost zlib"
    ;;
  ios_simulator )
    ARCH="i386"
    export CROSS_TOP="${DEVELOPER_PATH}/Platforms/iPhoneSimulator.platform/Developer"
    export CROSS_SDK="iPhoneSimulator${IPHONE_DEPLOYMENT_TARGET}.sdk"
	export CC="${CROSS_TOP}/usr/bin/gcc -arch ${ARCH}"
    CONFIGURE_FLAGS="iphoneos-cross no-gost zlib"
	;;
  * )
    echo "Unknown build platform: ${PLATFORM}"
	exit -1
esac


##############################################################
# Check to see if already built, ignore if so

PREFIX="${BUILD}/${VERSION}/${PLATFORM}"

if [ -e "${PREFIX}" ] && [ ${CLEAN} == 0 ]
then
  echo "Assuming already exists: ${PREFIX}"
  exit 0
fi

##############################################################
# remove existing build directory, unarchive

# Check for the UNARCHIVE  directories, use TMP if necessary
if [ "${UNARCHIVE}" == "" ]
then
UNARCHIVE="${TMPDIR}/${VERSION}/src"
fi

if [ ! -d "${UNARCHIVE}" ]
then
echo "mkdir ${UNARCHIVE}"
mkdir -pv "${UNARCHIVE}"
fi

rm -fr "${UNARCHIVE}"
mkdir "${UNARCHIVE}"
tar -C "${UNARCHIVE}" -zxf "${TARZ}"

##############################################################
# Building

pushd "${UNARCHIVE}/${VERSION}"

echo "Derived data: ${UNARCHIVE}"
echo "    Build to: ${PREFIX}"
echo "Architecture: ${ARCH}"
echo "       Flags: ${CONFIGURE_FLAGS}"

./Configure ${CONFIGURE_FLAGS} --openssldir="${PREFIX}"
if [ ${?} != 0 ]; then
  echo "Error building openssl"
  exit -1
fi

sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} !" "Makefile"
make && make install_sw

if [ ${?} != 0 ]; then
  echo "Error building openssl"
  exit -1
fi

popd

##############################################################
# Make symbolic links

rm -f "${BUILD}/openssl-current-${PLATFORM}"
ln -s "${PREFIX}" "${BUILD}/openssl-current-${PLATFORM}"
echo "${BUILD}/openssl-current-${PLATFORM}"
exit 0


