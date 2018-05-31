#!/bin/bash -eux

cd "$OUTPUT_BASE_DIR"

if [ -e "$ARTIFACT_FILENAME.vdi" ]; then
	echo "tarring up the vdi file now"
	tar -czf $ARTIFACT_FILENAME.vdi.tar.gz $ARTIFACT_FILENAME.vdi
	echo "vdi tar file ready"
else
	echo "vdi file NOT tarred"
fi
