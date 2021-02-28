#!/bin/bash

#loading functions
. $(dirname "$0")/functions.sh

# setting up python environment
python3 -m venv venv
# activate python environment
source venv/bin/activate
# installation of requirements
# requirements can be added that are needed for pandoc filters
pip install -r ./base/.pandoc/requirements.txt --no-binary :all:

#loading env settings
yml_to_env "$(get_settings "settingsCompile" "./settingsGlobal.yml")" | sed "s/.*\[.*\].*//" > debug.env
source base/bin/base.env
source debug.env
export DEBUG

#generate Documents according to loaded settings (Type: automatic book, manual book, single source; format: pdf, docx)
if [[ ${OUTPUT_FORMAT_PDF} = true ]] ; then
    [[ ${CREATE_AUTOMATIC_BOOKS} = true ]] && get_automatic_books | xargs -d '\n' -I{} -n1 -P${THREADS} /bin/bash -c './base/bin/make-files.sh --a --pdf --source "{}" '
    [[ ${CREATE_MANUAL_BOOKS} = true ]] && get_manual_book_source | xargs -d '\n' -I{} -n1 -P${THREADS} /bin/bash -c './base/bin/make-files.sh --m --pdf --source "{}" '
    [[ ${CREATE_FROM_SINGLE_SRC} = true ]] && find . -maxdepth ${SEARCH_DEPTH} -type f -name "${MARKDOWN_FILENAME}${MARKDOWN_EXTENSION}" -not -path '*/\.*' -print0 | xargs -0 -I{} -n1 -P${THREADS} /bin/bash -c './base/bin/make-files.sh --pdf --source "{}" '
fi
if [[ ${OUTPUT_FORMAT_DOCX} = true ]] ; then
    [[ ${CREATE_AUTOMATIC_BOOKS} = true ]] && get_automatic_books | xargs -d '\n' -I{} -n1 -P${THREADS} /bin/bash -c './base/bin/make-files.sh --a --docx --source "{}" '
    [[ ${CREATE_MANUAL_BOOKS} = true ]] && get_manual_book_source | xargs -d '\n' -I{} -n1 -P${THREADS} /bin/bash -c './base/bin/make-files.sh --m --docx --source "{}" '
    [[ ${CREATE_FROM_SINGLE_SRC} = true ]] && find . -maxdepth ${SEARCH_DEPTH} -type f -name "${MARKDOWN_FILENAME}${MARKDOWN_EXTENSION}" -not -path '*/\.*' -print0 | xargs -0 -I{} -n1 -P${THREADS} /bin/bash -c './base/bin/make-files.sh --docx --source "{}" '
fi

echo FINISHED CREATION


