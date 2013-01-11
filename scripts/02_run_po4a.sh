#!/bin/sh

set -e

CMAKE_CURRENT_SOURCE_DIR=$1
PO4A_FILE=$2

export PERLLIB=${CMAKE_CURRENT_SOURCE_DIR}/scripts/perllib

po4a -v -f $PO4A_FILE
