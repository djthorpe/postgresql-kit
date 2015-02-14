#!/bin/sh

## Copyright 2009-2015 David Thorpe
## https://github.com/djthorpe/postgresql-kit
##
## Licensed under the Apache License, Version 2.0 (the "License"); you may not
## use this file except in compliance with the License. You may obtain a copy
## of the License at http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
## WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
## License for the specific language governing permissions and limitations
## under the License.

## Create headerdocs

HEADERDOC_BIN=`which headerdoc2html`
GATHERDOC_BIN=`which gatherheaderdoc`
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE="${1}"
DESTINATION_PATH="${DERIVED_SOURCES_DIR}"
SOURCE_PATH="${CURRENT_PATH}/../src/${SOURCE}"

##############################################################
# Sanity checks

if [ "${#}" == "0" ] || [ "${SOURCE}" == "" ] || [ ! -e "${SOURCE_PATH}" ]
then
	echo "Syntax error: ${SCRIPT_NAME} <source code folder>"
	echo "Source ${SOURCE_PATH}"
	exit 1
fi

##############################################################
# Output

if [ "${DESTINATION_PATH}" == "" ]
then
	DESTINATION_PATH="${TMPDIR}"
fi

DESTINATION_PATH="${DESTINATION_PATH}/${SOURCE}"

if [ -d "${DESTINATION_PATH}" ]
then
	rm -fr "${DESTINATION_PATH}"
fi

if [ ! -d "${DESTINATION_PATH}" ]
then
  echo "mkdir ${DESTINATION_PATH}"
  mkdir -pv "${DESTINATION_PATH}"
fi

##############################################################
# run header doc

${HEADERDOC_BIN} -q -j -C -o "${DESTINATION_PATH}" "${SOURCE_PATH}" 2>&1 1>/dev/null
${GATHERDOC_BIN} "${DESTINATION_PATH}" "index.html"

echo "Output: ${DESTINATION_PATH}"


