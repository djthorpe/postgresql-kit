#!/bin/bash
# Build iOS apps in Release configuration
#
# Syntax:
#   build-iosapps.sh

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGURATION=Release
PROJECT=${CURRENT_PATH}/../postgresql-kit.xcodeproj

# Build iOS iApps
xcodebuild -project ${PROJECT} -target "PGClientKit_ios" -configuration ${CONFIGURATION} || exit -1
#xcodebuild -project ${PROJECT} -target "PGClient_ios" -configuration ${CONFIGURATION} || exit -1
