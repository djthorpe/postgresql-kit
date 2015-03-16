#!/bin/bash
# Build Mac OS X apps in Release configuration
#
# Syntax:
#   build-macapps.sh

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGURATION=Release
PROJECT=${CURRENT_PATH}/../postgresql-kit.xcodeproj

# Build Foundation Apps
xcodebuild -project ${PROJECT} -target "PGFoundationClient" -configuration ${CONFIGURATION} || exit -1
xcodebuild -project ${PROJECT} -target "PGFoundationServer" -configuration ${CONFIGURATION} || exit -1

# Build Cocoa Apps
#xcodebuild -project ${PROJECT} -target "PGClient" -configuration ${CONFIGURATION} || exit -1
#xcodebuild -project ${PROJECT} -target "PGServer" -configuration ${CONFIGURATION} || exit -1

