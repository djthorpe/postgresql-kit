#!/bin/bash
# Make FAT library, and create a symbolic link to the compiled package.
#
# Syntax:
#   lipo.sh (input_directory) (package) (library name) --platform=...
#

##############################################################
# Process command line arguments

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INPUT_DIR=${1}
PACKAGE=${2}
LIBRARY=${3}
PLATFORMS=()

for ARG in "${@:4}"
do
  case ${ARG} in
    --platform=* )
      PLATFORMS+=(`echo ${ARG} | sed 's/[-a-zA-Z0-9]*=//'`)
      ;;
    * )
  	  echo "Unrecognised argument: ${ARG}"
      exit 1
      ;;
  esac
done

##############################################################
# Architectures

DEVELOPER_PATH=`xcode-select --print-path`
if [ ! -d "$DEVELOPER_PATH" ]; then
  echo "XCode not installed"
  exit -1
fi

DEVROOT="${DEVELOPER_PATH}/Platforms/iPhoneOS.platform/Developer"

for PLATFORM in ${PLATFORMS[@]}
do
  case ${PLATFORM} in
    ios_armv7 )
      ARCH="armv7"
      LIB_PATH="${INPUT_DIR}/${PACKAGE}-${PLATFORM}/${LIBRARY}"
	  LIPO_ARGS="${LIPO_ARGS} -arch ${ARCH} ${LIB_PATH}"
      ;;
    ios_armv7s )
      ARCH="armv7s"
      LIB_PATH="${INPUT_DIR}/${PACKAGE}-${PLATFORM}/${LIBRARY}"
      LIPO_ARGS="${LIPO_ARGS} -arch ${ARCH} ${LIB_PATH}"
      ;;
    ios_arm64)
      ARCH="arm64"
      LIB_PATH="${INPUT_DIR}/${PACKAGE}-${PLATFORM}/${LIBRARY}"
      LIPO_ARGS="${LIPO_ARGS} -arch ${ARCH} ${LIB_PATH}"
      ;;
    ios_simulator32 )
      ARCH="i386"
      LIB_PATH="${INPUT_DIR}/${PACKAGE}-${PLATFORM}/${LIBRARY}"
      LIPO_ARGS="${LIPO_ARGS} -arch ${ARCH} ${LIB_PATH}"
      ;;
    ios_simulator64 )
      ARCH="x86_64"
      LIB_PATH="${INPUT_DIR}/${PACKAGE}-${PLATFORM}/${LIBRARY}"
      LIPO_ARGS="${LIPO_ARGS} -arch ${ARCH} ${LIB_PATH}"
      ;;
    * )
      echo "Invalid platform: ${PLATFORM}"
      exit 1
      ;;
  esac
  if [ ! -f "${LIB_PATH}" ] ; then
    echo "Invalid library path: ${LIB_PATH}"
    exit 1
  fi
done

LIPO_COMMAND="${DEVROOT}/usr/bin/lipo"
LIPO_OUTPUT="${INPUT_DIR}/${PACKAGE}/${LIBRARY}"
LIPO_PATH=`dirname ${LIPO_OUTPUT}`
LIPO_ARGS="${LIPO_ARGS} -create -output ${LIPO_OUTPUT}"

if [ ! -d "${LIPO_PATH}" ]
then
  echo "mkdir ${LIPO_PATH}"
  mkdir -pv "${LIPO_PATH}"
fi

${LIPO_COMMAND} ${LIPO_ARGS}

exit 0

