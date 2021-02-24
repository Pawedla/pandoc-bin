#!/bin/bash
echo "./_index.pandoc"
find . -type f -name "*${MARKDOWN_EXTENSION}" -not -name "_index${MARKDOWN_EXTENSION}" | sort