#!/bin/bash -eux
echo "Running post process script for vmware"
cd "$OUTPUT_BASE_DIR"
echo "OUTPUT_BASE_DIR: $OUTPUT_BASE_DIR"
echo "ARTIFACT_FILENAME: $ARTIFACT_FILENAME"
# Replace string 'ide1:0.present = "TRUE"' with 'ide1:0.present = "FALSE"'
#TMP_FILE="$PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BASE_IMAGE/$BUILDER/$ARTIFACT_FILENAME.vmx"
TMP_FILE="$OUTPUT_BASE_DIR/$ARTIFACT_FILENAME.vmx"
echo "tmp file: $TMP_FILE"
# echo "Changing ide1 presence to false"
# if [ "$(uname)" == "Darwin" ]; then
#     # Do something under Mac OS X platform        
# 	sed -i '' 's#ide1:0.present = \"TRUE\"#ide1:0.present = \"FALSE\"#g' $TMP_FILE
# elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
#     # Do something under GNU/Linux platform
# 	sed -i"any_symbol" 's#ide1:0.present = \"TRUE\"#ide1:0.present = \"FALSE\"#g' $TMP_FILE
# elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
#     # Do something under Windows NT platform
#     echo "Unable to perform sed replacement"
# fi

echo "generating ovf file"
if [ "$(uname)" == "Darwin" ]; then
    # Do something under Mac OS X platform
    echo "\"/Applications/VMware Fusion.app/Contents/Library/VMware OVF Tool/ovftool\" --noImageFiles $OUTPUT_BASE_DIR/$ARTIFACT_FILENAME.vmx $OUTPUT_BASE_DIR/ovf/$ARTIFACT_FILENAME.ovf"
	"/Applications/VMware Fusion.app/Contents/Library/VMware OVF Tool/ovftool" --noImageFiles $OUTPUT_BASE_DIR/$ARTIFACT_FILENAME.vmx $OUTPUT_BASE_DIR/ovf/$ARTIFACT_FILENAME.ovf
	echo "ovf file generated"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
	ovftool --noImageFiles $OUTPUT_BASE_DIR/$ARTIFACT_FILENAME.vmx $OUTPUT_BASE_DIR/ovf/$ARTIFACT_FILENAME.ovf
	echo "ovf file generated"
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    # Do something under Windows NT platform
    echo "Unable to run ovf tool"
fi
