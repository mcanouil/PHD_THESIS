#!/bin/sh

Rscript -e "bookdown::render_book(input = 'index.Rmd', output_format = 'bookdown::pdf_document2', encoding = 'UTF-8')"
Rscript -e "bookdown::render_book(input = 'index.Rmd', output_format = 'bookdown::word_document2', encoding = 'UTF-8')"
