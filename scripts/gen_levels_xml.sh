#!/bin/sh

set -e

srcdir=$1
outdir=$2

if [ -z "$srcdir" ] || [ "$srcdir" = "." ] || [ ! -d $srcdir ] || \
   [ -z "$outdir" ] || [ "$outdir" = "." ] || [ ! -d $outdir ]; then
	echo "No existing input or output directories provided; syntax is : $0 source_directory output_directory"
	return 1;
fi

linguas="en fr"

common_i18n_ext=xhtml

gen_i18n_file () {

levelfileorig=$1
common_i18n_file=$2

if [ -z "$levelfileorig" ] || [ ! -f $levelfileorig ]; then
	echo "No file name provided; syntax is : $0 filename.txt"
	return 1;
fi

levelfile=$(basename $levelfileorig .txt)

destfile=$levelfile.xml;
allsfile=$common_i18n_file.$common_i18n_ext;

echo "<$levelfile>" > $destfile
echo "<h1><!-- Level: $levelfile --></h1>" >> $allsfile
for key in Title Resume ScriptName; do
	for subkey in text resume; do
		subval=$(grep "^$key\.E.*$subkey" $levelfileorig | sed -e "s/^.*$subkey=\"\([^\"]*\)\".*$/\1/")
		# Always write entries, even when empty, otherwise breaks po4a-gettextize
		echo "<${key}_$subkey>$levelfile:$subval</${key}_$subkey>" >> $destfile
		echo "<p type=\"$key $subkey\">$levelfile:$subval</p>" >> $allsfile
	done
done
echo "</$levelfile>" >> $destfile

echo "[type:xml] $levelfile.xml \$lang:$levelfile.\$lang.xml" >> po4a.cfg

echo -n "."
}

rm -f *.xml
rm -f po4a.cfg

echo " 0 - Create initial files"

echo "[po_directory] po/" > po4a.cfg
mkdir -p po

echo -n " 1 - Generate transitional source translation files from level files"

echo "<html><body>" > level.$common_i18n_ext
for lang in $linguas; do
	if [ $lang = "en" ]; then continue; fi;
	echo "<html><body>" > $lang.$common_i18n_ext
done

for level in $(cd $srcdir/; ls *.txt); do
	if [ "$level" != "CMakeLists.txt" -a "$level" != "install_manifest.txt" -a "$level" != "CMakeCache.txt" ]; then
		gen_i18n_file $srcdir/$level level
	fi
done
echo "</body></html>" >> level.$common_i18n_ext

echo "done"

echo -n " 3 - Generate pristine potfile: "
po4a-gettextize -M UTF-8 -f xhtml -m level.$common_i18n_ext > po/level.pot 2>/dev/null
echo "done"

echo -n " 4 - Generate translation files: "
for lang in $linguas; do
	if [ $lang = "en" ]; then continue; fi;
	echo -n "$lang "
	echo "</body></html>" >> $lang.$common_i18n_ext
	pofile=po/$lang.po
	if [ ! -f $pofile ]; then
		sed -e 's/charset=CHARSET/charset=UTF-8/g' po/level.pot > $pofile
	fi
	po4a-updatepo -M UTF-8 -f xhtml -m level.$common_i18n_ext -p $pofile 2>/dev/null
done
echo " done"

echo -n " 5 - Cleanup po4a infrastructure, run po4a … "
po4a -f po4a.cfg 2>/dev/null 1>&2
echo "done"

echo -n " 6 - Inject translation in level files: "

for levelfile in $(cd $srcdir; ls *.txt); do
	# Always start afresh
	rm -f $outdir/$levelfile

	rootfilename=$(basename $levelfile .txt)
	for lang in $linguas; do
		dotlang=".$lang"
		langcode="";
		case $lang in
			en) dotlang=""; langcode=".E";;
			fr) langcode=".F";;
			pl) langcode=".P";;
		esac
		xmlfile=$rootfilename$dotlang.xml
		echo -n "."
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
					echo "$key$langcode$lineend" >> $outdir/$levelfile
				fi
			done
		fi
	done
	sed -e '/^Title/d;/^Resume/d;/^ScriptName/d' $srcdir/$levelfile >> $outdir/$levelfile
done
echo "done."
