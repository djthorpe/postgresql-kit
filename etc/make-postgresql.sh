#!/bin/bash

# Make postgresql from source in the tar subdirectory
# Syntax:
#   make-postgresql.sh ${INPUT_TAR} ${OUTPUT_DIR}

CLEAN=0
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UNARCHIVE=${DERIVED_SOURCES_DIR}
TARZ=${1}
BUILD=${2}
VERSION=`basename ${TARZ} | sed 's/\.tar\.gz//'`

# Check for openssl installation
if [ "${OPENSSL}XX" != "XX" ] && [ -d ${OPENSSL} ]
then
  echo "Using openssl libraries: ${OPENSSL}"
  MY_INC=${OPENSSL}/include
  MY_LIB=${OPENSSL}
else
  MY_INC=""
  MY_LIB=""
fi

# Check for the TAR file to make sure it exists
if [ "${TARZ}XX" == "XX" ] || [ ! -e ${TARZ} ]
then
	echo "Syntax error: make-postgresql.sh {INPUT_TAR_GZ} {OUTPUT_FOLDER}"
	exit 1
fi

# Check for the BUILD directory
if [ "${BUILD}XX" == "XX" ] || [ ! -d ${BUILD} ]
then
    echo "Syntax error: make-postgresql.sh {INPUT_TAR_GZ} {OUTPUT_FOLDER}"
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
echo "Built postgres with be installed at ${PREFIX}"

# remove existing build directory, unarchive
rm -fr "${UNARCHIVE}"
mkdir "${UNARCHIVE}"
tar -C ${UNARCHIVE} -zxvf ${TARZ}

# configure - for 10.6, we only support 64-bit architecture
cd "${UNARCHIVE}/${VERSION}"
export CFLAGS="-arch x86_64"
export LDFLAGS="-arch x86_64"
./configure --prefix="${PREFIX}" --enable-thread-safety --without-readline --with-bonjour --with-openssl --with-libxml --with-libxslt --disable-rpath --with-includes=${MY_INC} --with-libs=${MY_LIB}

# make and install
make
make install

# make symbolic link
rm -f ${BUILD}/postgresql-current
ln -s ${PREFIX} ${BUILD}/postgresql-current
exit 0

