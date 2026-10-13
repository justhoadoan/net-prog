#!/usr/bin/env sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
mkdir -p build

if [ -x .tools/tectonic ]; then
  .tools/tectonic --keep-logs --outdir build topic-identification.tex
elif command -v tectonic >/dev/null 2>&1; then
  tectonic --keep-logs --outdir build topic-identification.tex
elif command -v latexmk >/dev/null 2>&1 && command -v xelatex >/dev/null 2>&1; then
  latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=build topic-identification.tex
elif command -v xelatex >/dev/null 2>&1; then
  xelatex -interaction=nonstopmode -halt-on-error -output-directory=build topic-identification.tex
  xelatex -interaction=nonstopmode -halt-on-error -output-directory=build topic-identification.tex
else
  printf '%s\n' 'Install Tectonic or XeLaTeX first; see README.md.' >&2
  exit 1
fi
printf '%s\n' 'PDF: build/topic-identification.pdf'
