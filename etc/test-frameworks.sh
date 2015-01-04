#!/bin/bash
# Test all frameworks in Debug configuration
#
# Syntax:
#   test-frameworks.sh

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGURATION=Debug
PROJECT=${CURRENT_PATH}/../postgresql-kit.xcodeproj

# Test Frameworks
xcodebuild test -project ${PROJECT} -scheme "PGServerKit_testcases" -configuration ${CONFIGURATION}  || exit -1
xcodebuild test -project ${PROJECT} -scheme "PGClientKit_testcases" -configuration ${CONFIGURATION}  || exit -1
#xcodebuild -project ${PROJECT} -target "PGSchemaKit_testcases" -configuration ${CONFIGURATION} || exit -1

