#!/bin/sh

set -e

echo "[po_directory] $1"
shift 1

for scene in "$@"; do
	echo "[type:xml] $scene.xml \$lang:$scene.\$lang.xml"
done
