#!/bin/bash -eux

echo "changing to directory $OUTPUT_BASE_DIR"
cd "$OUTPUT_BASE_DIR"

chmod -Rf 777 $OUTPUT_BASE_DIR

echo "converting raw file $ARTIFACT_FILENAME to qcow2 file $ARTIFACT_FILENAME.qcow2"
qemu-img convert -c -O qcow2 $ARTIFACT_FILENAME $ARTIFACT_FILENAME.qcow2

echo "qcow2 file generated"

echo "converting qcow2 file to raw file"
qemu-img convert -O raw $ARTIFACT_FILENAME.qcow2 $ARTIFACT_FILENAME.raw

echo "raw file generated"

echo "tarring up the raw file now"
tar -czf $ARTIFACT_FILENAME.raw.tar.gz $ARTIFACT_FILENAME.raw

echo "raw tar file ready"
