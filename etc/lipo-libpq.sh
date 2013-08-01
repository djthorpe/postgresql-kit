#!/bin/bash

# Make FAT libpq library, and create a symbolic link
# to the compiled package.
#
# Syntax:
#   lipo-libpq.sh (input_directory) (flags)
#

##############################################################
# Process command line arguments

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIPO_ARGS=""
INPUT_DIR=$1

##############################################################
# Architectures

DEVELOPER_PATH=`xcode-select --print-path`
DEVROOT="${DEVELOPER_PATH}/Platforms/iPhoneOS.platform/Developer"

for ARG in "$@"
do
  case ${ARG} in
    ios_armv7 )
      ARCH="armv7"
      LIBPQ_PATH="${INPUT_DIR}/libpq-current-${ARG}/lib"
      LIPO_ARGS="${LIPO_ARGS} -arch ${ARCH} ${LIBPQ_PATH}/libpq.a"
      ;;
    ios_armv7s )
      ARCH="armv7s"
      LIBPQ_PATH="${INPUT_DIR}/libpq-current-${ARG}/lib"
      LIPO_ARGS="${LIPO_ARGS} -arch ${ARCH} ${LIBPQ_PATH}/libpq.a"
      ;;
    ios_simulator )
      ARCH="i386"
      LIBPQ_PATH="${INPUT_DIR}/libpq-current-${ARG}/lib"
      LIPO_ARGS="${LIPO_ARGS} -arch ${ARCH} ${LIBPQ_PATH}/libpq.a"
      ;;
  esac
done

LIPO_COMMAND="${DEVROOT}/usr/bin/lipo"
LIPO_ARGS="${LIPO_ARGS} -create -output ${INPUT_DIR}/libpq.a"

${LIPO_COMMAND} ${LIPO_ARGS}

