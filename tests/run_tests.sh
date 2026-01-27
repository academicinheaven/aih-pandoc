#!/bin/bash
set -euo pipefail

mkdir -p /tmp/home /tmp/xdg-cache /tmp/xdg-config /tmp/matplotlib

export HOME=/tmp/home
export XDG_CACHE_HOME=/tmp/xdg-cache
export XDG_CONFIG_HOME=/tmp/xdg-config
export MPLCONFIGDIR=/tmp/matplotlib
export PYTHONHISTFILE=/tmp/python_history
export PYTHONDONTWRITEBYTECODE=1

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
    echo "FAILED: pandoc could not be found."
    exit 1
fi
echo "PASSED: pandoc is installed."

# Check if pandoc returns version
pandoc --version > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
  echo "PASSED: pandoc is installed and working correctly."
else
  echo "FAILED: pandoc is not installed or failed to run."
  exit 1
fi

# Check if pandoc-crossref returns version
pandoc-crossref --version > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
  echo "PASSED: pandoc-crossref is installed and working correctly."
else
  echo "FAILED: pandoc-crossref is not installed or failed to run."
  exit 1
fi

# Check if pandoc-plot returns version
pandoc-plot --version > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
  echo "PASSED: pandoc-plot is installed and working correctly."
else
  echo "FAILED: pandoc-plot is not installed or failed to run."
  exit 1
fi

# Check if Python binary exists
if ! command -v python >/dev/null 2>&1; then
  echo "FAILED: Python binary not found in PATH."
  exit 1
fi
# Check if Python runs
if ! python --version >/dev/null 2>&1; then
  echo "FAILED: Python is installed but failed to run."
  exit 1
fi

echo "PASSED: Python is installed and working correctly."

# Check Matplotlib
python -c "import matplotlib; print(matplotlib.__version__)" \
  | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+' \
  && echo "PASSED: Matplotlib OK" \
  || { echo "FAILED: Matplotlib test"; return 1; }

mkdir -p /tmp/tests
rm -f /tmp/tests/*

# Convert md file to html
pandoc test.md -o /tmp/tests/test.html > /dev/null 2>&1
# Check if the HTML file was created
if [ -f /tmp/tests/test.html ]; then
    echo "PASSED: pandoc successfully converted test.md to test.html."
    rm -f /tmp/tests/*
else
    echo "FAILED: pandoc failed to convert test.md to test.html."
    exit 1
fi

# Pandoc citeproc
# Convert md file to html
pandoc --citeproc test-citeproc.md -o /tmp/tests/test-citeproc.html > /dev/null 2>&1
# Check if the HTML file was created
if [ -f /tmp/tests/test-citeproc.html ]; then
    echo "PASSED: pandoc successfully created test-citeproc.html."
    cat /tmp/tests/test-citeproc.html
    rm -f /tmp/tests/*
else
    echo "FAILED: pandoc failed to create test-citeproc.html."
    exit 1
fi

# TODO: Test pandoc-crossref
# Maybe based on 
# https://github.com/lierdakil/pandoc-crossref/blob/master/docs/demo/demo.md?plain=1

# Test pandoc-plot
# Matplotlib should be available
# Convert md file to html
pandoc --filter pandoc-plot -i test-pandoc-plot.md -o /tmp/tests/test-pandoc-plot.html > /dev/null 2>&1
# Check if the HTML file was created
if [ -f /tmp/tests/test-pandoc-plot.html ]; then
    echo "PASSED: pandoc-plot successfully converted test-pandoc-plot.md to test-pandoc-plot.html."
else
    echo "FAILED: pandoc failed to convert test.md to test.html."
    exit 1
fi
# Check if SVG image has been created
# Note: You cannot control the file name with pandoc-plot
if [ -f /tmp/tests/*.svg ]; then
    echo "PASSED: pandoc-plot created SVG file."
    ls /tmp/tests/*.svg
    rm -f /tmp/tests/*
else
    echo "FAILED: pandoc failed to create SVG file."
    ls /tmp/tests/
    rm -f /tmp/tests/*
    exit 1
fi

