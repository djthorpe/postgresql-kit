#!/bin/bash

# Reversion all plist files

##############################################################
# Process command line arguments

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$( basename $0 )
BIN="${CURRENT_PATH}/reversion-plist.sh"

${BIN} \
	src/Frameworks/PGServerKit/PGServerKit.plist \
	src/Frameworks/PGClientKit/PGClientKit_ios.plist \
	src/Frameworks/PGClientKit/PGClientKit_mac.plist \
	src/Frameworks/PGControlsKit/PGControlsKit.plist \
	src/Frameworks/PGDataKit/PGDataKit_mac.plist \
	src/Apps/Cocoa/PGClient/Info.plist



