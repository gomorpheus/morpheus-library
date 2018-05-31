#!/bin/bash -eux

cd "$OUTPUT_BASE_DIR"

if [ -e "$ARTIFACT_FILENAME" ]; then
	mv $ARTIFACT_FILENAME $ARTIFACT_FILENAME.raw 
	echo ".raw file type appended to raw file"
else
	echo "raw file NOT renamed"
fi

if [ -e "$ARTIFACT_FILENAME.raw" ]; then
	echo "converting raw file to vdi file"
	VBoxManage convertdd $ARTIFACT_FILENAME.raw $ARTIFACT_FILENAME.vdi --format VDI
	echo "vdi file generated"
else
	echo "raw file NOT converted to vdi file"
fi

if [ -e "$ARTIFACT_FILENAME.raw" ]; then
	echo "tarring up the raw file now"
	tar -czf $ARTIFACT_FILENAME.raw.tar.gz $ARTIFACT_FILENAME.raw
	echo "raw tar file ready"
else
	echo "raw file NOT tarred"
fi

if [ -e "$ARTIFACT_FILENAME.vdi" ]; then
	echo "tarring up the vdi file now"
	tar -czf $ARTIFACT_FILENAME.vdi.tar.gz $ARTIFACT_FILENAME.vdi
	echo "vdi tar file ready"
else
	echo "vdi file NOT tarred"
fi
