#!/bin/bash

OUTPUT_DIR="build"

while [[ $# -gt 0 ]] ; do
    case $1 in
        -s|--source)
            SOURCE="$2"
            shift
            shift;;
        --pdf)
            OUTPUT_FORMAT="pdf"
            shift;;
        --docx)
            OUTPUT_FORMAT="docx"
            shift;;
        --a)
            CREATION_TYPE=automatic
            shift;;
        --m)
            CREATION_TYPE=manual
            shift;;
    esac
done

. $(dirname "$0")/functions.sh

# Setup environment variables
source $(dirname "$0")/setup.sh 
cd "$WORKING_DIR"

# Create temporary markdown file
if [[ ${BOOK} = true ]] ; then
    if [[ ${CREATION_TYPE} = automatic ]] ; then
        find . -type f \( -name "settings.yml" -o -name "${MARKDOWN_FILENAME}${MARKDOWN_EXTENSION}" \) | sed 's/settings.yml/_.yml/' | env LC_COLLATE=C sort | sed 's/_.yml/settings.yml/' > ${FILENAME_TEMP}.index
    else    
        get_manual_books ${SOURCE} > ${FILENAME_TEMP}.index
    fi
    [[ ${DEBUG} = true ]] && echo Files to parse:
    [[ ${DEBUG} = true ]] && cat $FILENAME_TEMP.index
    # Combine files
    while read p; do
        if [[ $p = "./settings.yml" ]] ; then
            create_frontmatter "book" > $FILENAME_TEMP
        else
            DIR=$(dirname "${p}")
            if [[ $(basename "${p}") = "settings.yml" ]] ; then
                sed -n '/part/{s/.*:[[:space:]]*//;p}' $p >> $FILENAME_TEMP
                print_empty_lines ${FILENAME_TEMP}
            else
            sed 's@\(!\[.*\]\)(\(.*\))\(.*\)@\1('"$DIR"'\/\2)\3@g' ${p} >> $FILENAME_TEMP
            print_empty_lines ${FILENAME_TEMP}
            fi
        fi
    done < $FILENAME_TEMP.index  
    
else
    create_frontmatter "single" > $FILENAME_TEMP
    sed '0,/#.*/s///' ${BASENAME}${MARKDOWN_EXTENSION} >> $FILENAME_TEMP
    print_empty_lines ${FILENAME_TEMP}
fi

###############################################################################
# Pandoc filter
###############################################################################
# demote headings if content file
[[ ! $BOOK = true ]] && FILTER_DEMOTE_HEADER="--filter demoteHeaders.hs"

## pandoc-crossref
if [[ ${PANDOC_CROSSREF} = true ]] ; then
    [[ -e "$BIN_DIR/pandoc-crossref.yml" ]] && CROSSREF_PRESET_FILE="$BASE_DIR/$BIN_DIR/pandoc-crossref.yml"
    [[ -e "$BASE_DIR/pandoc-crossref.yml" ]] && CROSSREF_PRESET_FILE="$BIN_DIR/pandoc-crossref.yml"
    [[ -e "$WORKING_DIR/pandoc-crossref.yml" ]] && CROSSREF_PRESET_FILE="$BIN_DIR/pandoc-crossref.yml"
    COMMAND_CROSSREF="--filter pandoc-crossref -M crossrefYaml=${CROSSREF_PRESET_FILE}"
fi

# pandoc-citeproc
if [[ ${PANDOC_CITEPROC} = true ]] ; then
    COMMAND_CITEPROC="--citeproc"
    [[ -e ${BASE_DIR}/${CITEPROC_BIBLIOGRAPHY} && ${BIBLIOGRAPHY_BY_DIRECTORY} = false ]] && COMMAND_CITEPROC="${COMMAND_CITEPROC} -M bibliography=$BASE_DIR/${CITEPROC_BIBLIOGRAPHY} -M link-citations -M reference-section-title=Literaturverzeichnis"
    [[ -n ${CITEPROC_STYLE} && -e ${BASE_DIR}/.pandoc/csl/${CITEPROC_STYLE} ]] && COMMAND_CITEPROC="${COMMAND_CITEPROC} --csl=${BASE_DIR}/.pandoc/csl/${CITEPROC_STYLE}"
fi

# qr code for youtube videos
[[ ${PANDOC_YOUTUBE_VIDEO_LINKS} = true ]] && COMMAND_YOUTUBE_FILTER="--filter pandoc-youtube-video-links.py"
[[ ${PANDOC_AWESOME_BOX} = true ]] && COMMAND_AWESOME_FILTER="--filter pandoc_alert_boxes.py"

if [[ $OUTPUT_FORMAT = "pdf" ]]; then
    [[ ${USE_LISTINGS} = true ]] && COMMAND_LISTINGS="--listings -M listings=true"
    [[ ! -z $(grep "\chapter{.*}\|\part{.*}" "$FILENAME_TEMP") ]] && COMMAND_BOOK="-V book"
    
    ## change division level for content files if set
    [[ -n ${DIVISION_LEVEL} && ${BOOK} = true ]] && COMMAND_TOP_LEVEL_DIVISION="--top-level-division=${DIVISION_LEVEL}"
    TEMPLATE="--template=${PANDOC_PDF_TEMPLATE}"
    PANDOC_COMMAND="${PANDOC_COMMAND} --pdf-engine=xelatex -s"
fi

if [[ $OUTPUT_DIR = "." && $OUTPUT_FORMAT = "pdf" ]] ; then
    OUTPUT_DIR="$BASE_DIR/${OUTPUT_DIR}/${OUTPUT_FORMAT}/$WORKING_DIR"
    BASENAME=$(basename $WORKING_DIR)  
    echo Basename is now $BASENAME
else
    OUTPUT_DIR="$BASE_DIR/${OUTPUT_DIR}/${OUTPUT_FORMAT}/$WORKING_DIR"
fi

mkdir -p "$OUTPUT_DIR"
echo OUTPUT_FILE "$OUTPUT_DIR/$BASENAME.${OUTPUT_FORMAT}"
echo ${PANDOC_COMMAND} $FILENAME_TEMP -o \""$OUTPUT_DIR/$BASENAME.${OUTPUT_FORMAT}"\" \
    ${FILTER_DEMOTE_HEADER} \
    ${COMMAND_CROSSREF} \
    ${COMMAND_CITEPROC} \
    ${TEMPLATE} \
    ${COMMAND_YOUTUBE_FILTER} \
    ${COMMAND_AWESOME_FILTER} \
    ${COMMAND_BOOK} \
    ${COMMAND_LISTINGS} \
    ${COMMAND_TOP_LEVEL_DIVISION} \
    ${CUSTOM} \
    ${CUSTOM_APPEND} \
    -V logo-jku=$BASE_DIR/.pandoc/templates/jku_de.pdf \
    -V logo-k=$BASE_DIR/.pandoc/templates/arr.pdf \
    -V img-cc=$BASE_DIR/.pandoc/templates/cc.png > start.sh 

bash start.sh

sudo rm start.sh
#[[ -e ${BASE_DIR}/debug.env ]] && sudo rm debug.env
#[[ -e $FILENAME_TEMP.index ]] && sudo rm $FILENAME_TEMP.index
#sudo rm -rf TEMP_*
echo Finished $BASENAME.${OUTPUT_FORMAT}
echo 
