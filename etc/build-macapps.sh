#!/bin/bash
# Build Mac OS X apps in Release configuration
#
# Syntax:
#   build-macapps.sh

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGURATION=Release
PROJECT=${CURRENT_PATH}/../postgresql-kit.xcodeproj

# Build Mac Apps
xcodebuild -project ${PROJECT} -target "PGCmd" -configuration ${CONFIGURATION} || exit -1
xcodebuild -project ${PROJECT} -target "PGServer" -configuration ${CONFIGURATION} || exit -1
xcodebuild -project ${PROJECT} -target "PGClient" -configuration ${CONFIGURATION} || exit -1


