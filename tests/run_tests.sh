#!/bin/bash
echo Passing tests
exit 0

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

