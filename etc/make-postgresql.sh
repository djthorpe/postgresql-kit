#!/bin/bash

#!/bin/bash

# Make postgresql from source, and create a symbolic link
# to the compiled package.
#
# Syntax:
#   make-postgresql.sh (input_tar) (output_directory) (flags)
#
# Flags:
#   --clean will always rebuild from clean sources
#   --platform=<platform> will built for one of these
#      architectures:
#         mac_x86_64
#   --openssl=<openssl> will use external version of
#      openssl, previously built

##############################################################
# Process command line arguments

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UNARCHIVE="${DERIVED_SOURCES_DIR}"
TARZ="${1}"
BUILD="${2}"
CLEAN=0
PLATFORM=mac_x86_64
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
  echo "Syntax error: make-postgresql.sh {INPUT_TAR_GZ} {OUTPUT_FOLDER} (--clean) (--openssl={OPENSSL}) (--platform=mac_x86_64)"
  exit 1
fi

# Check for the BUILD directory
if [ "${BUILD}XX" == "XX" ] || [ ! -d ${BUILD} ]
then
  echo "Syntax error: make-postgresql.sh {INPUT_TAR_GZ} {OUTPUT_FOLDER} (--clean) (--openssl={OPENSSL}) (--platform=mac_x86_64)"
  exit 1
fi

# Check for openssl installation
if [ "${OPENSSL}" != "" ] && [ -d ${OPENSSL} ]
then
  echo "Using openssl libraries: ${OPENSSL}"
fi

##############################################################
# Set version number

VERSION=`basename ${TARZ} | sed 's/\.tar\.gz//'`
if [ ! -d "${UNARCHIVE}" ]
then
  echo "mkdir ${UNARCHIVE}"
  mkdir -pv "${UNARCHIVE}"
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
  mac_x86_64 )
    ARCH="x86_64"
    DEVROOT="${DEVELOPER_PATH}/Platforms/MacOSX.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/MacOSX${MACOSX_DEPLOYMENT_TARGET}.sdk"
	unset IPHONEOS_DEPLOYMENT_TARGET
    ;;
  * )
    echo "Unknown build platform: ${PLATFORM}"
    exit 1
esac

CC="/usr/bin/gcc -arch ${ARCH}"
CPPFLAGS=""
CFLAGS="-isysroot ${SDKROOT} ${CPPFLAGS}"
LDFLAGS="-Wl,-syslibroot,${SDKROOT} -lz"
CONFIGURE_FLAGS="--enable-thread-safety --without-readline --with-ldap --with-bonjour --with-libxml --with-libxslt"

if [ -d "${OPENSSL}" ]
then
  WITH_INCLUDES="${OPENSSL}/include"
  WITH_LIBS="${OPENSSL}/lib"
  CONFIGURE_FLAGS="${CONFIGURE_FLAGS} --with-openssl --with-includes=${WITH_INCLUDES} --with-libs=${WITH_LIBS}"
fi

##############################################################
# Check to see if already built, ignore if so

PREFIX="${BUILD}/${VERSION}/${PLATFORM}"

if [ -e "${PREFIX}" ] && [ ${CLEAN} == 0 ]
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

./configure CC="${CC}" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CPPFLAGS="${CPPFLAGS}" --prefix="${PREFIX}" ${CONFIGURE_FLAGS}
make && make install

if [ $? != 0 ]; then
  echo "Error building postgresql"
  exit -1
fi

popd

##############################################################
# Make symbolic links

rm -f "${BUILD}/postgresql-current-${PLATFORM}"
ln -s "${PREFIX}" "${BUILD}/postgresql-current-${PLATFORM}"
echo "${BUILD}/postgresql-current-${PLATFORM}"

