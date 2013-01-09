#!/bin/sh

set -e

levelfile=$1
translations_prefix=$2
rootfilename=$(basename $translations_prefix)

# Autodetect translated languages
script_path=$(dirname $0)
po_path="$(dirname $script_path)/po"
linguas=$(cd $po_path/; ls *.po | sed -e 's/\.po$//g')

# Make sure we take english (first, but it's not really important)
for lang in en $linguas; do
	dotlang=".$lang"
	langcode="";
	case $lang in
		en) dotlang=""; langcode=".E";;
		fr) langcode=".F";;
		pl) langcode=".P";;
	esac
	xmlfile=$translations_prefix$dotlang.xml
	if [ -f $xmlfile ]; then
		for key in Title Resume ScriptName; do
			lineend=""
			for subkey in text resume; do
				keyval=$(grep "^<${key}_${subkey}>" $xmlfile | sed -e "s|^<${key}\_${subkey}>${rootfilename}:\(.*\)<\/${key}\_${subkey}>$|\1|g")
				if [ -n "$keyval" ]; then
					lineend="$lineend $subkey=\"$keyval\""
				fi
			done
			if [ -n "$lineend" ]; then
				echo "$key$langcode$lineend"
			fi
		done
	fi
done
echo "// End of level headers translations"
echo ""
sed -e '/^Title/d;/^Resume/d;/^ScriptName/d' $levelfile
