#!/bin/sh

title_name=
if [ -n "$1" ]; then
    title_name=$1
else
    title_name=${CGIT_REPO_NAME}
fi

/usr/bin/pandoc \
  -M pagetitle="${title_name}" \
  --data-dir /srv/www/pandoc-data \
  --from markdown+lists_without_preceding_blankline \
  --to html5+smart \
  --template=cgit-buttondown \
  --include-before-body="/srv/www/pandoc-data/css/style-open.html" \
  --include-before-body="/srv/www/pandoc-data/css/cgit-buttondown.css" \
  --include-before-body="/srv/www/pandoc-data/css/style-close.html" \
  --toc

