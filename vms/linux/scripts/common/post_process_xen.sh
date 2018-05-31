#!/bin/bash -eux

cd "$OUTPUT_BASE_DIR"

sudo chmod -Rf 777 $OUTPUT_BASE_DIR

TMP_RAW_FILE=(${prefix}*.raw)

echo "Backing up TMP_RAW_FILE: $TMP_RAW_FILE"

cp $TMP_RAW_FILE $TMP_RAW_FILE.orig

echo "Converting raw to fixed vhd"

vhd-util convert -i $TMP_RAW_FILE -o $ARTIFACT_FILENAME.vhd -s 0 -t 1

echo "Converting fixed vhd to dynamic vhd (vpc)"

vhd-util convert -i $ARTIFACT_FILENAME.vhd -o $ARTIFACT_FILENAME.vhd -s 1 -t 2

echo "tarring up the vhd file now"

tar -czf $ARTIFACT_FILENAME.vhd.tar.gz $ARTIFACT_FILENAME.vhd

echo "vhd tar file ready"

