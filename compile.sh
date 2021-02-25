#!/bin/bash

. $(dirname "$0")/functions.sh

python3 -m venv venv
source venv/bin/activate
pip install -r ./base/.pandoc/requirements.txt --no-binary :all:

yml_to_env "$(get_settings "settingsCompile" "./settingsGlobal.yml")" | sed "s/.*\[.*\].*//" > debug.env
source base/bin/base.env
source debug.env
export DEBUG

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


