#!/bin/bash

. $(dirname "$0")/functions.sh

printf "%100s\n" |tr " " "="
printf "%-40s%s\n" "Source:" ${SOURCE} 
printf "%100s\n" |tr " " "="

# Set directory variables
BASE_DIR="$(git rev-parse --show-toplevel)" # working directory of the docker image (/usr/share/blog)
BIN_DIR=${BASE_DIR}/base/bin # relative path to the scripts directory (./bin)
WORKING_DIR=$(dirname "${SOURCE}") # relative direcrory of the current source file
[[ ${CREATION_TYPE} = manual || ${CREATION_TYPE} = automatic ]] && WORKING_DIR=${SOURCE}

[[ ${DEBUG} = true ]] && printf "%-40s%s\n" "[BASE_DIR]:" ${BASE_DIR}
[[ ${DEBUG} = true ]] && printf "%-40s%s\n" "[BIN_DIR]:" ${BIN_DIR}
[[ ${DEBUG} = true ]] && printf "%-40s%s\n" "[WORKING_DIR]:" ${WORKING_DIR}
[[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="

# Check the file typ of the source file
if [[ ! $SOURCE =~ .md ]] ; then
    if [[ ${SOURCE} = . ]] ; then 
        BASENAME=$(basename "root" )
    else 
        BASENAME=$(basename "${SOURCE}")
    fi
        BOOK=true
else
    BASENAME=$(basename "${SOURCE}" .md)
    BOOK=false
fi

# Read minimum base enviroment variables
store_env "${BIN_DIR}/base.env" debug.env $BOOK "base enviroment file"
store_env "${BASE_DIR}/settingsGlobal.yml" debug.env $BOOK "file for project enviroment"
yml_to_env "$(get_settings "settingsCompile" "./settingsGlobal.yml")" | sed -n "/MARKDOWN_EXTENSION=/{p;q}" >> debug.env
store_env "${WORKING_DIR}/settings.yml" debug.env $BOOK "file for wdir enviroment"
source ./debug.env

[[ ${DEBUG} = true ]] && printf "%-40s%s\n" "Basename:" ${BASENAME}
[[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="

# Override with CI Parameters
[[ -n ${GENERATE_QR_CODES} ]] && PANDOC_YOUTUBE_VIDEO_LINKS=${GENERATE_QR_CODES}
[[ ${GENERATE_QR_CODES} = true && ! ${CI_COMMIT_REF_NAME} = master ]] && PANDOC_YOUTUBE_VIDEO_LINKS=${GENERATE_QR_CODES_FOR_BRANCHES}

# Temporary Filename
FILENAME_TEMP=TEMP_$(basename "${BASENAME}" ${MARKDOWN_EXTENSION})${MARKDOWN_EXTENSION}
[[ ${DEBUG} = true ]] && printf "%-40s%s\n" "Temporary file:" ${FILENAME_TEMP}
[[ ${DEBUG} = true ]] && printf "%100s\n" |tr " " "="