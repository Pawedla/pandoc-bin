#!/bin/bash
find . -type f -name "*${MARKDOWN_EXTENSION}" | sort | grep "_index${MARKDOWN_EXTENSION}\|${MARKDOWN_FILENAME}${MARKDOWN_EXTENSION}"