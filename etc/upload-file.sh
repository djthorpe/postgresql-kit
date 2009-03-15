#!/bin/sh

# upload-file.sh
# postgresql
#
# Created by David Thorpe on 15/03/2009.
# Copyright 2009 __MyCompanyName__. All rights reserved.

ETC_DIR=`dirname $0`
SCRIPT_NAME=`basename $0`
PROJECT_DIR=${ETC_DIR}/..
PROGRAM_NAME='googlecode_upload.py'
PROGRAM_PATH=${ETC_DIR}/${PROGRAM_NAME}
PROJECT_NAME='postgres-kit'
PROJECT_USER='david.thorpe'
PROJECT_PASSWORD=`cat ~/.ssh/googlecode`


if [ ! -e ${PROGRAM_PATH} ]; then
  echo "Unable to locate program: ${PROGRAM_NAME}"
  exit -1
fi

################################################################################

UPLOAD_LABELS="Featured"
UPLOAD_FILENAME=$1

if [ "${UPLOAD_FILENAME}zz" = "zz" ]; then
  echo "Syntax error: ${SCRIPT_NAME} <filename>"
  exit -1
fi

if [ ! -e ${UPLOAD_FILENAME} ]; then
  echo "File not found: ${UPLOAD_FILENAME}"
  exit -1
fi


echo "Uploading ${UPLOAD_FILENAME}"

python ${PROGRAM_PATH} --project=${PROJECT_NAME} \
       --user=${PROJECT_USER} --password=${PROJECT_PASSWORD} \
	   --labels=${UPLOAD_LABELS} --summary=${UPLOAD_FILENAME} \
	   ${UPLOAD_FILENAME}
   



