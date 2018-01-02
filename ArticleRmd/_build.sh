#!/bin/sh

Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::pdf_document2')"
Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::word_document2')"
