#!/bin/sh

set -e

# Source file
levelfileorig=$1
levelfile=$(basename $levelfileorig .txt)

# Destination XML
levelfiledest=$2
# Destination partial HTML
commonfiledest=$3

levelcontent="<$levelfile>"
commoncontent="<h1><!-- Level: $levelfile --></h1>"
for key in Title Resume ScriptName; do
	for subkey in text resume; do
		subval=$(grep "^$key\.E.*$subkey" $levelfileorig | sed -e "s/^.*$subkey=\"\([^\"]*\)\".*$/\1/")
		# Always write entries, even when empty, otherwise breaks po4a-gettextize
		levelcontent="$levelcontent\n<${key}_$subkey>$levelfile:$subval</${key}_$subkey>"
		commoncontent="$commoncontent\n<p type=\"$key $subkey\">$levelfile:$subval</p>"
	done
done
levelcontent="$levelcontent\n</$levelfile>"

# Attempt to make that atomic
echo "$levelcontent" > $levelfiledest
echo "$commoncontent" > $commonfiledest
