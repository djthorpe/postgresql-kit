#!/bin/bash

#Build all targets for a particular platform
#
# Syntax:
#   build-all.sh (flags)
#
# Flags:
#   --clean will always rebuild from clean sources
#   --platform=<platform> will built for one of these
#      architectures:
#         mac ios

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGURATION=Release
PROJECT=${CURRENT_PATH}/../postgresql-kit.xcodeproj

# TO BUILD FOR iOS
xcodebuild -project ${PROJECT} -target "openssl - iOS" -configuration ${CONFIGURATION} || exit -1
#xcodebuild -project ${PROJECT} -target "libpq - iOS" -configuration ${CONFIGURATION} || exit -1
#xcodebuild -project ${PROJECT} -target "PGClientKit - iOS" -configuration ${CONFIGURATION} || exit -1

# TO BUILD FOR Mac
#xcodebuild -project ${PROJECT} -target "openssl - Mac" -configuration ${CONFIGURATION} || exit -1
#xcodebuild -project ${PROJECT} -target "postgresql - Mac" -configuration ${CONFIGURATION} || exit -1
#xcodebuild -project ${PROJECT} -target "PGServerKit - Mac" -configuration ${CONFIGURATION} || exit -1
#xcodebuild -project ${PROJECT} -target "PGClientKit - Mac" -configuration ${CONFIGURATION} || exit -1



