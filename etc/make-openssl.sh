#!/bin/bash

# Make openssl from source in the tar subdirectory
# Syntax:
#   make-openssl.sh ${INPUT_TAR} ${OUTPUT_DIR}

CLEAN=0
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UNARCHIVE=${DERIVED_SOURCES_DIR}
TARZ=${1}
BUILD=${2}
VERSION=`basename ${TARZ} | sed 's/\.tar\.gz//'`

# Check for the TAR file to make sure it exists
if [ "${TARZ}XX" == "XX" ] || [ ! -e ${TARZ} ]
then
	echo "Syntax error: make-openssl.sh {INPUT_TAR_GZ} {OUTPUT_FOLDER}"
	exit 1
fi

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

PREFIX=${BUILD}/${VERSION}

if [ -e ${PREFIX} ] && [ ${CLEAN} == 0 ]
then
  echo "Assuming already exists: ${PREFIX}"
  exit 0
fi

echo "Unarchiving sources to ${UNARCHIVE}"
echo "Built openssl with be installed at ${PREFIX}"

# remove existing build directory, unarchive
rm -fr "${UNARCHIVE}"
mkdir "${UNARCHIVE}"
tar -C ${UNARCHIVE} -zxvf ${TARZ}


# 32-bit architecture
cd "${UNARCHIVE}/${VERSION}"
./Configure darwin-i386-cc --prefix=${PREFIX}
make && make install

exit 0


./Configure darwin64-x86_64-cc
make

#cd ../
#lipo -create openssl_i386/libcrypto.1.0.0.dylib openssl_x86_64/libcrypto.1.0.0.dylib -output libcrypto.1.0.0.dylib
#lipo -create openssl_i386/libssl.1.0.0.dylib openssl_x86_64/libssl.1.0.0.dylib -output libssl.1.0.0.dylib
#rm openssl-$OPENSSL_VERSION.tar.gz
