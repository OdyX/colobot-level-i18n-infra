#!/bin/sh

set -e

# Source file
levelfileorig=$1
levelfile=$(basename $levelfileorig .txt)

# Destination XML
levelfiledest=$2
# Destination partial HTML
commonfiledest=$3

echo "<$levelfile>" > $levelfiledest
echo "<h1><!-- Level: $levelfile --></h1>" > $commonfiledest
for key in Title Resume ScriptName; do
	for subkey in text resume; do
		subval=$(grep "^$key\.E.*$subkey" $levelfileorig | sed -e "s/^.*$subkey=\"\([^\"]*\)\".*$/\1/")
		# Always write entries, even when empty, otherwise breaks po4a-gettextize
		echo "<${key}_$subkey>$levelfile:$subval</${key}_$subkey>" >> $levelfiledest
		echo "<p type=\"$key $subkey\">$levelfile:$subval</p>" >> $commonfiledest
	done
done
echo "</$levelfile>" >> $levelfiledest
