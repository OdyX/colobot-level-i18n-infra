#!/bin/sh

set -e

# MUST be run from ${CMAKE_CURRENT_BINARY_DIR}

srcdir=$1 # absolute
po_directory=$2 # relative
leveldir=$3 # relative
helpdir=$4 # relative

ln -sf $srcdir/$po_directory $po_directory
echo "[po_directory] $po_directory"

# Create symlink for relative paths in po4a
mkdir -p $leveldir

# Levels are precompiled, they are already in the current dir
for scene in $(cd $srcdir/$leveldir; ls *.txt); do
	scene_=$(basename $scene .txt)
	$(cd $leveldir; ln -sf $srcdir/$leveldir/$scene $scene)
	echo "[type:colobotlevel] $leveldir/$scene \$lang:$leveldir/$scene_.\$lang.txt"
done

# Create symlink for relative paths in po4a
mkdir -p $helpdir

for helpfile in $(cd $srcdir/$helpdir; ls *.txt); do
	helpfile_=$(basename $helpfile .txt)
	$(cd $helpdir; ln -sf $srcdir/$helpdir/$helpfile $helpfile)
	echo "[type:colobothelp] $helpdir/$helpfile \$lang:$helpdir/$helpfile_.\$lang.txt"
done
