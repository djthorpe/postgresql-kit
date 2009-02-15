#!/bin/sh

# syntax: install-postgres-server-app.sh install (<data folder>) 
#     or: install-postgres-server-app.sh uninstall

RESOURCES_PATH="$( dirname "$0" )"
SCRIPT_NAME="$( basename "$0" )"

NAME_PLIST=PostgresPrefPaneServerStartupItem
BUNDLE_PATH=${RESOURCES_PATH}/../..
LAUNCHCTL_LABEL="$( defaults read "${BUNDLE_PATH}/Contents/Resources/${NAME_PLIST}" Label )"

PATH_PLIST_SRC="${BUNDLE_PATH}/Contents/Resources/${NAME_PLIST}.plist"
DOMAIN_PLIST_DEST="/Library/LaunchDaemons/com.mutablelogic.${NAME_PLIST}"
PATH_PLIST_DEST="${DOMAIN_PLIST_DEST}.plist"
PATH_APP=${BUNDLE_PATH}/Contents/MacOS/PostgresServerApp
PATH_DATA="/Library/Application Support/PostgreSQL"

################################################################################

SyntaxError() {
	echo "Syntax: ${SCRIPT_NAME} install"
	echo "    or: ${SCRIPT_NAME} uninstall"
}

InstallService() {
  # Uninstall any previous instance first
  UninstallService

  # Check for source plist    
  if [ ! -e "${PATH_PLIST_SRC}" ]
  then
    echo "Error: plist does not exist: ${PATH_PLIST_SRC}"
	exit -1
  fi
  
  echo "Copy from ${PATH_PLIST_SRC}"
  echo "    ...to ${PATH_PLIST_DEST}"
  
  cp "${PATH_PLIST_SRC}" "${PATH_PLIST_DEST}"
  if [ z"$?" != z"0" ]
  then
    echo "Error: Unable to perform plist copy: $?"
	exit -1
  fi

  # write defaults, set as XML
  defaults write ${DOMAIN_PLIST_DEST} ProgramArguments -array -string "${PATH_APP}" -string "-data" -string "${PATH_DATA}"
  plutil -convert xml1 ${PATH_PLIST_DEST}    
  chmod 644 ${PATH_PLIST_DEST}
  
  # load it into launchctl
  launchctl load ${PATH_PLIST_DEST}
}

UninstallService() {
  # see if service is loaded return=0 yes
  launchctl list ${LAUNCHCTL_LABEL}  2>&1 >/dev/null
  if [ z"$?" == z"0" ]
  then
    launchctl unload ${PATH_PLIST_DEST}
  fi
  
  # Remove destination plist    
  if [ -e "${PATH_PLIST_DEST}" ]
  then
    rm "${PATH_PLIST_DEST}"
  fi
}


################################################################################

if [ "\$#" == "0" ] ; then
    SyntaxError
else
    case $1 in 
	install) InstallService ;;
	uninstall) UninstallService ;;
	*) SyntaxError ;;
    esac
fi
