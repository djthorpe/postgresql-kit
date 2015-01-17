#!/bin/bash

# Reversion a application and/or framework plist file depnding on the
# current git branch version
#
# Syntax:
#   reversion-plist.sh (input_plist ...)

##############################################################
# Process command line arguments

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$( basename $0 )
BIN="/usr/libexec/Plistbuddy"
PLIST="$1"
PLIST_VERSION="${CURRENT_PATH}/../doc/Version.plist"

if [ ! -x "${BIN}" ] ; then
	echo "Not found: Plistbuddy"
	exit -1
fi

for PLIST_FILE in "$@"
do
	if [ ! -f "${CURRENT_PATH}/../${PLIST_FILE}" ] ; then
		echo "Not found: ${PLIST_FILE}"
		exit -1
	fi
done


##############################################################
# Determine version

# get our version info from git
GIT=`which git`
TAG=`${GIT} describe --tags`
BRANCH=`${GIT} name-rev HEAD --name-only --always`

# split tag into <release>-<v>-<num>-<hash>
RELEASE_TYPE=$( echo "${TAG}" | cut -d "-" -f 1 )
RELEASE_VERSION=$( echo "${TAG}" | cut -d "-" -f 2 )
RELEASE_COUNTER=$( echo "${TAG}" | cut -d "-" -f 3 )
RELEASE_HASH=$( echo "${TAG}" | cut -d "-" -f 4 )

if [ "${RELEASE_COUNTER}XX" = "XX" ] ; then
	RELEASE_COUNTER="0"
fi

# the tag format should be as follows, where {version} is a three digit number:
#  alpha-{version} => 0.1{version}.{counter}
#  beta-{version} => 0.2{version}.{counter}
#  release-{version} => 1.3{version}.{counter}
# future major version changes should be alpha1, beta2, release3 and so forth
# but this is not yet implemented!

case ${RELEASE_TYPE} in
  "alpha" )
    RELEASE_VERSION="1${RELEASE_VERSION}"
  ;;
  "beta" )
    RELEASE_VERSION="2${RELEASE_VERSION}"
  ;;
  "release" )
    RELEASE_VERSION="3${RELEASE_VERSION}"
  ;;
  "*" )
    echo "Invalid release type: ${RELEASE_TYPE}"
	exit -1
esac

CF_BUNDLE_VERSION="0.${RELEASE_VERSION}.${RELEASE_COUNTER}"

##############################################################
# Perform operations

rm -f "${PLIST_VERSION}"
${BIN} -x -c "Add TAG string \"${TAG}\"" "${PLIST_VERSION}" > /dev/null
${BIN} -x -c "Add BRANCH string \"${BRANCH}\"" "${PLIST_VERSION}"
${BIN} -x -c "Add RELEASE_TYPE string \"${RELEASE_TYPE}\"" "${PLIST_VERSION}"
${BIN} -x -c "Add RELEASE_VERSION string \"${RELEASE_VERSION}\"" "${PLIST_VERSION}"
${BIN} -x -c "Add RELEASE_COUNTER integer \"${RELEASE_COUNTER}\"" "${PLIST_VERSION}"
${BIN} -x -c "Add RELEASE_HASH string \"${RELEASE_HASH}\"" "${PLIST_VERSION}"
${BIN} -x -c "Add CF_BUNDLE_VERSION string \"${CF_BUNDLE_VERSION}\"" "${PLIST_VERSION}"

for PLIST_FILE in "$@"
do
	${BIN} -c "Set :CFBundleVersion \"${CF_BUNDLE_VERSION}\"" "${CURRENT_PATH}/../${PLIST_FILE}"
	${BIN} -c "Set :CFBundleShortVersionString \"${CF_BUNDLE_VERSION}\"" "${CURRENT_PATH}/../${PLIST_FILE}"
done

echo "CFBundleVersion=${CF_BUNDLE_VERSION}"
exit 0





