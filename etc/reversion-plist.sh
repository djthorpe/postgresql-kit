#!/bin/sh

# Which plist file
PLIST="$1"

if [ ! -f "${PLIST}" ] ; then
	echo "Not found: ${PLIST}"
	exit -1
fi

# get our version info from git
GIT=`which git`
TAG=`${GIT} describe --tags`
BRANCH=`${GIT} name-rev HEAD --name-only --always`

# output info
echo "TAG=${TAG}"
echo "BRANCH=${BRANCH}"

/usr/libexec/Plistbuddy -c "Set :CFBundleVersion \"${TAG}\"" "${PLIST}"