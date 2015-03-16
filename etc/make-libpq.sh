#!/bin/bash

# Make libpq from source, and create a symbolic link
# to the compiled package.
#
# Syntax:
#   make-libpq.sh (input_tar) (output_directory) (flags)
#
# Flags:
#   --clean will always rebuild from clean sources
#   --platform=<platform> will built for one of these
#      architectures:
#         mac_x86_64 ios_armv7 ios_armv7s ios_arm64 ios_simulator32 ios_simulator64
#   --openssl=<openssl> will use external version of
#      openssl, previously built

##############################################################
# Process command line arguments

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UNARCHIVE="${DERIVED_SOURCES_DIR}"
TARZ=${1}
BUILD=${2}
CLEAN=0
PLATFORM=ios_armv7
OPENSSL=

for ARG in "$@"
do
  case ${ARG} in
    --clean )
      CLEAN=1
      ;;
    --platform=* )
      PLATFORM=`echo ${ARG} | sed 's/[-a-zA-Z0-9]*=//'`
      ;;
    --openssl=* )
      OPENSSL=`echo ${ARG} | sed 's/[-a-zA-Z0-9]*=//'`
      ;;
  esac
done

##############################################################
# Sanity checks

# Check for the TAR file to make sure it exists
if [ "${#}" == "0" ] || [ "${TARZ}" == "" ] || [ ! -e "${TARZ}" ]
then
  echo "Syntax error: make-libpq.sh {INPUT_TAR_GZ} {OUTPUT_FOLDER} (--clean) (--platform=mac_x86_64|ios_armv7|ios_armv7s|ios_arm64|ios_simulator32|ios_simulator64)"
  exit 1
fi

##############################################################
# Set version number

VERSION=`basename ${TARZ} | sed 's/\.tar\.gz//'`

# Check for the BUILD directory
if [ "${BUILD}XX" == "XX" ] || [ ! -d ${BUILD} ]
then
  echo "Syntax error: make-libpq.sh {INPUT_TAR_GZ} {OUTPUT_FOLDER} (--clean) (--platform=mac_x86_64|ios_armv7|ios_armv7s|ios_arm64|ios_simulator32|ios_simulator64)"
  exit 1
fi

##############################################################
# Architectures

DEVELOPER_PATH=`xcode-select --print-path`
if [ ! -d "$DEVELOPER_PATH" ]; then
  echo "XCode not installed"
  exit -1
fi

if [ "${MACOSX_DEPLOYMENT_TARGET}XX" == "XX" ]
then
	MACOSX_DEPLOYMENT_TARGET=10.10
fi

if [ "${IPHONEOS_DEPLOYMENT_TARGET}XX" == "XX" ]
then
	IPHONEOS_DEPLOYMENT_TARGET=8.0
fi

case ${PLATFORM} in
  ios_armv7 )
    ARCH="armv7"
    DEVROOT="${DEVELOPER_PATH}/Platforms/iPhoneOS.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/iPhoneOS${IPHONEOS_DEPLOYMENT_TARGET}.sdk"
	unset MACOSX_DEPLOYMENT_TARGET
    ;;
  ios_armv7s )
    ARCH="armv7s"
    DEVROOT="${DEVELOPER_PATH}/Platforms/iPhoneOS.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/iPhoneOS${IPHONEOS_DEPLOYMENT_TARGET}.sdk"
	unset MACOSX_DEPLOYMENT_TARGET
    ;;
  ios_arm64 )
    ARCH="arm64"
    DEVROOT="${DEVELOPER_PATH}/Platforms/iPhoneOS.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/iPhoneOS${IPHONEOS_DEPLOYMENT_TARGET}.sdk"
	unset MACOSX_DEPLOYMENT_TARGET
    ;;
  ios_simulator32 )
    ARCH="i386"
    DEVROOT="${DEVELOPER_PATH}/Platforms/iPhoneSimulator.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/iPhoneSimulator${IPHONEOS_DEPLOYMENT_TARGET}.sdk"
	unset MACOSX_DEPLOYMENT_TARGET
    ;;
  ios_simulator64 )
    ARCH="x86_64"
    DEVROOT="${DEVELOPER_PATH}/Platforms/iPhoneSimulator.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/iPhoneSimulator${IPHONEOS_DEPLOYMENT_TARGET}.sdk"
	unset MACOSX_DEPLOYMENT_TARGET
    ;;
  * )
    echo "Unknown build platform: ${PLATFORM}"
    exit 1
esac

#CC="${DEVELOPER_PATH}/usr/bin/gcc -arch ${ARCH}"
CC="/usr/bin/gcc -arch ${ARCH}"
CPPFLAGS="-I${SDKROOT}/usr/lib/gcc/arm-apple-darwin9/4.0.1/include/ -I${SDKROOT}/usr/include/"
#CPPFLAGS="-I$/usr/lib/gcc/arm-apple-darwin9/4.0.1/include/ -I$/usr/include/"
CFLAGS="-isysroot ${SDKROOT} ${CPPFLAGS}"
LDFLAGS="-Wl,-syslibroot,${SDKROOT} -lz"
CONFIGURE_FLAGS="--host=arm-apple-darwin --enable-thread-safety --without-readline"

if [ -d "${OPENSSL}" ]
then
  WITH_INCLUDES="${OPENSSL}/include"
  WITH_LIBS="${OPENSSL}/lib"
  CONFIGURE_FLAGS="${CONFIGURE_FLAGS} --with-openssl --with-includes=${WITH_INCLUDES} --with-libs=${WITH_LIBS}"
fi

##############################################################
# Check to see if already built, ignore if so

PREFIX=${BUILD}/${VERSION}/${PLATFORM}

if [ -e ${PREFIX} ] && [ ${CLEAN} == 0 ]
then
  echo "Assuming already exists: ${PREFIX}"
  exit 0
fi


##############################################################
# Check SDK's exist

SDK_AVAILABILITY=`xcodebuild -showsdks | sed -n 's/.*\-sdk \(.*\)/\1/p'`

if [ "${MACOSX_DEPLOYMENT_TARGET}" ]
then
	# look for -sdk macosx${MACOSX_DEPLOYMENT_TARGET}
    if [[ ${SDK_AVAILABILITY} != *"macosx${MACOSX_DEPLOYMENT_TARGET}"* ]]
	then
		echo "SDK does not exist: macosx${MACOSX_DEPLOYMENT_TARGET}"
		exit -1
	fi
fi

if [ "${IPHONEOS_DEPLOYMENT_TARGET}" ]
then
	# look for -sdk iphoneos${IPHONEOS_DEPLOYMENT_TARGET}
    if [[ ${SDK_AVAILABILITY} != *"iphoneos${IPHONEOS_DEPLOYMENT_TARGET}"* ]]
	then
		echo "SDK does not exist: iphoneos${IPHONEOS_DEPLOYMENT_TARGET}"
		exit -1
	fi

	# look for -sdk iphonesimulator${IPHONEOS_DEPLOYMENT_TARGET}
    if [[ ${SDK_AVAILABILITY} != *"iphonesimulator${IPHONEOS_DEPLOYMENT_TARGET}"* ]]
	then
		echo "SDK does not exist: iphonesimulator${IPHONEOS_DEPLOYMENT_TARGET}"
		exit -1
	fi

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
echo "         SDK: ${MACOSX_DEPLOYMENT_TARGET}${IPHONEOS_DEPLOYMENT_TARGET}"
echo "       Flags: ${CONFIGURE_FLAGS}"

./configure CC="${CC}" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CPPFLAGS="${CPPFLAGS}" --prefix="${PREFIX}" ${CONFIGURE_FLAGS}
make -C src/interfaces/libpq || exit -1
make -C src/interfaces/libpq install || exit -1

popd

##############################################################
# Copy postgres-ext.h

cp "${UNARCHIVE}/${VERSION}/src/include/postgres_ext.h" "${PREFIX}/include"

##############################################################
# Copy pg_config.h

cp "${UNARCHIVE}/${VERSION}/src/include/pg_config_ext.h" "${PREFIX}/include"
cp "${UNARCHIVE}/${VERSION}/src/include/pg_config.h" "${PREFIX}/include"

##############################################################
# Make symbolic links

rm -f "${BUILD}/libpq-current-${PLATFORM}"
ln -s "${PREFIX}" "${BUILD}/libpq-current-${PLATFORM}"

##############################################################
# Success

echo
echo
echo "Installed: ${BUILD}/libpq-current-${PLATFORM}"
echo

exit 0







