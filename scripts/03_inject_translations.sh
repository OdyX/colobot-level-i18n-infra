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
	if [ "$lang" = "en" ]; then
		dotlang="";
	fi
	i18nfile=$translations_prefix$dotlang.txt
	if [ -f $i18nfile ]; then
		sed -n '/^Title/p;/^Resume/p;/^ScriptName/p' $i18nfile
	fi
done
echo "// End of level headers translations"
echo ""
sed -e '/^Title/d;/^Resume/d;/^ScriptName/d' $levelfile
