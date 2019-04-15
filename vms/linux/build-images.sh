#!/bin/bash

#	VirtualBox examples
#	./build-images.sh virtualbox-vdi ubuntu-14_04_5 amd64 ubuntu 14_04_5 v1 1
#	./build-images.sh virtualbox-vdi ubuntu-14_04_6 amd64 ubuntu 14_04_6 v1 1
#	./build-images.sh virtualbox-vdi ubuntu-16_04_6 amd64 ubuntu 16_04_6 v1 1
#	./build-images.sh virtualbox-vdi ubuntu-16_04_6 i386 ubuntu 16_04_6 v1 1
#	./build-images.sh virtualbox-vdi ubuntu-18_04_2 amd64 ubuntu 18_04_2 v1 1
#	./build-images.sh virtualbox-vdi centos-7_5 x86_64 centos 7_5 v1 1

#	./build-images.sh virtualbox-vdi ubuntu-14_04_6 amd64 apache 2_4 v1

#	VMWare examples
#	./build-images.sh vmware ubuntu-16_04_6 amd64 ubuntu 16_04_6 v1 1
#	./build-images.sh vmware centos-7_5 x86_64 centos 7_5 v1 1

#	./build-images.sh vmware ubuntu-14_04_6 amd64 apache 2_4 v1

#	KVM examples
#	./build-images.sh kvm ubuntu-16_04_6 amd64 ubuntu 16_04_6 v1 1

#	Amazon examples
#	./build-images.sh amazon ubuntu-16_04_6 amd64 ubuntu 16_04_6 v1 1

baseimages=(centos-6_8 centos-6_9 centos-7_2 centos-7_3 centos-7_5 oel-7_3 rhel-7_2 rhel-7_3 ubuntu-12_04 ubuntu-14_04_3 ubuntu-14_04_5-amd64 ubuntu-14_04_6-amd64 ubuntu-16_04_4-amd64 ubuntu-16_04_5-amd64 ubuntu-16_04_6-amd64 ubuntu-17_10_1-amd64 ubuntu-18_04_2-amd64 windows-2012_r2)
builders=(vmware virtualbox-qemu kvm amazon xen virtualbox-vdi ovm)
ubuntubases=(ubuntu-12_04 ubuntu-14_04_3 ubuntu-14_04_5-amd64 ubuntu-14_04_6-amd64 ubuntu-16_04_4-amd64 ubuntu-16_04_5-amd64 ubuntu-16_04_6-amd64 ubuntu-17_10_1-amd64 ubuntu-18_04_2-amd64)
centosbases=(centos-6_8 centos-6_9 centos-7_2 centos-7_3 centos-7_5)
oraclebases=(oel-7_3)
redhatbases=(rhel-7_2 rhel-7_3)
windowsbases=(windows-2012_r2)
platforms=(linux windows)
arch=(amd64 i386 x86_64)
debianarchs=(amd64 i386)

if [ "$#" -lt 6 ]; then

  echo "Usage: build_images.sh BUILDER BASE_IMAGE ARCHITECTURE INSTANCE_TYPE INSTANCE_VERSION MORPH_BUILD_VERSION, ex. build_images.sh vmware ubuntu-14_04 amd64 apache 2_4 v1" >&2

elif ! [[ ${builders[*]} =~ "$1" ]]; then

	echo "Builder $1 not recognized. Select from the following; vmware, virtualbox-qemu, kvm, amazon, xen, virtualbox-vdi, ovm"

elif ! [[ ${baseimages[*]} =~ "$2" ]]; then

#	echo "Base image $2 not recognized. Select from the following; centos-6_8, centos-7_2, centos-7_3, oracle-7_3, rhel-7_2, ubuntu-12_04, ubuntu-14_04, ubuntu-14_04_5-amd64, ubuntu-16_04_3-amd64, ubuntu-17_10-amd64, windows-2012_r2"
	echo "Base image $2 not recognized. Select from the following; centos-6_8, centos-6_9, centos-7_2, centos-7_3, centos-7_5, oracle-7_3, rhel-7_2, ubuntu-12_04, ubuntu-14_04, ubuntu-14_04_5, ubuntu-16_04_5, ubuntu-16_04_6, ubuntu-17_10_1, ubuntu-18_04_2, windows-2012_r2"

elif ! [[ ${arch[*]} =~ "$3" ]]; then

	echo "Architecture $3 not recognized. Select from the following; amd64, i386, x86_64"

else

	BASE_IMAGE=$2
#			BASE_OS=${BASE_IMAGE::${#BASE_IMAGE}-2}
	BASE_OS=$BASE_IMAGE
	BUILDER=$1
	ARCH=$3
#			INSTANCE_TYPE=$3
	INSTANCE_TYPE=$4
	INSTANCE_VERSION=$5
	MORPH_BUILD_VERSION=$6
	ARTIFACT_FOLDERNAME=$INSTANCE_TYPE-$INSTANCE_VERSION-$MORPH_BUILD_VERSION
	PACKER_TEMPLATE_VARIABLE_SUFFIX=""
	PACKER_TEMPLATE_BASE_SUFFIX="base"

	if [ -z "$7" ]; then
		BASE_IMAGE_ONLY=0
	else
		BASE_IMAGE_ONLY=$7
	fi

	if [ "$BASE_IMAGE_ONLY" = 0 ]; then
		ARTIFACT_FILENAME="morpheus"-$INSTANCE_TYPE-$INSTANCE_VERSION-$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
#		PACKER_TEMPLATE_VARIABLE_SUFFIX=-$ARCH
	else
		ARTIFACT_FILENAME="morpheus"-$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
		PACKER_TEMPLATE_VARIABLE_SUFFIX=-$ARCH
	fi

	if [[ ${centosbases[*]} =~ $BASE_IMAGE ]]; then
		BASE_OS=${BASE_IMAGE::${#BASE_IMAGE}-2}
	elif [[ ${redhatbases[*]} =~ $BASE_IMAGE ]]; then
		BASE_OS=${BASE_IMAGE::${#BASE_IMAGE}-2}
	elif [[ "ubuntu-14_04_3" = $BASE_IMAGE ]]; then
		BASE_OS=${BASE_IMAGE::${#BASE_IMAGE}-5}
	elif [[ "ubuntu-14_04_5" = $BASE_IMAGE ]]; then
		BASE_OS=${BASE_IMAGE::${#BASE_IMAGE}-5}
	elif [[ "ubuntu-14_04_6" = $BASE_IMAGE ]]; then
		BASE_OS=${BASE_IMAGE::${#BASE_IMAGE}-5}
	elif [[ "ubuntu-16_04_5" = $BASE_IMAGE ]]; then
		BASE_OS=${BASE_IMAGE::${#BASE_IMAGE}-5}
	elif [[ "ubuntu-16_04_6" = $BASE_IMAGE ]]; then
		BASE_OS=${BASE_IMAGE::${#BASE_IMAGE}-5}
	elif [[ "ubuntu-18_04_2" = $BASE_IMAGE ]]; then
		BASE_OS=${BASE_IMAGE::${#BASE_IMAGE}-5}
	elif [[ "ubuntu-17_10_1" = $BASE_IMAGE ]]; then
		BASE_OS=${BASE_IMAGE::${#BASE_IMAGE}-5}
	fi

	if [ "$BASE_IMAGE_ONLY" = 0 ]; then
		ARTIFACT_FOLDERNAME=$INSTANCE_TYPE-$INSTANCE_VERSION-$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
	else
		if [[ "ubuntu-14_04_5" = $BASE_IMAGE ]]; then
			ARTIFACT_FOLDERNAME=$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
		elif [[ "ubuntu-14_04_6" = $BASE_IMAGE ]]; then
			ARTIFACT_FOLDERNAME=$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
		elif [[ "ubuntu-16_04_3" = $BASE_IMAGE ]]; then
			ARTIFACT_FOLDERNAME=$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
		elif [[ "ubuntu-16_04_5" = $BASE_IMAGE ]]; then
			ARTIFACT_FOLDERNAME=$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
		elif [[ "ubuntu-16_04_6" = $BASE_IMAGE ]]; then
			ARTIFACT_FOLDERNAME=$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
		elif [[ "ubuntu-17_10_1" = $BASE_IMAGE ]]; then
			ARTIFACT_FOLDERNAME=$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
		elif [[ "ubuntu-18_04_2" = $BASE_IMAGE ]]; then
			ARTIFACT_FOLDERNAME=$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
		elif [[ "centos-7_3" = $BASE_IMAGE ]]; then
			ARTIFACT_FOLDERNAME=$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
		elif [[ "centos-7_5" = $BASE_IMAGE ]]; then
			ARTIFACT_FOLDERNAME=$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
		elif [[ "centos-6_9" = $BASE_IMAGE ]]; then
			ARTIFACT_FOLDERNAME=$BASE_IMAGE-$MORPH_BUILD_VERSION-$ARCH
		else
			ARTIFACT_FOLDERNAME=$BASE_IMAGE-$MORPH_BUILD_VERSION
		fi
	fi

	echo "PACKER_TEMPLATE_DIR: $PACKER_TEMPLATE_DIR"
	echo "selected builder: $BUILDER"
	echo "building for platform: $PLATFORM"
	echo "BASE_IMAGE: $BASE_IMAGE"
	echo "BASE_OS: $BASE_OS"
	echo "instance type: $INSTANCE_TYPE"
	echo "instance version: $INSTANCE_VERSION"
	echo "ARTIFACT_FOLDERNAME: $ARTIFACT_FOLDERNAME"
	echo "ARTIFACT_FILENAME: $ARTIFACT_FILENAME"
	echo "BASE_IMAGE_ONLY: $BASE_IMAGE_ONLY"
	echo "PACKER_TEMPLATE_VARIABLE_SUFFIX: $PACKER_TEMPLATE_VARIABLE_SUFFIX"
	echo "PACKER_TEMPLATE_BASE_SUFFIX: $PACKER_TEMPLATE_BASE_SUFFIX"
	echo "MORPH_BUILD_VERSION: $MORPH_BUILD_VERSION"

	if [[ $BUILDER == "vmware" ]]; then

		if [[ -d $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/ovf ]]; then
		  echo "ovf output directory exists we need to remove it"
		  sudo chmod -Rf 777 $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/ovf
		  rm -r $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/ovf
		fi

		if [[ -d $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER ]]; then
		  echo "output directory exists we need to remove it"
		  sudo chmod -Rf 777 $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER
		  rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/caches/screenshots/*
		  rmdir $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/caches/screenshots
		  rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/screenshots/*
		  rmdir $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/screenshots
		  rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/caches/*
		  rmdir $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/caches
		  rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/*
		  rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/.*
		  rmdir $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER
		fi

	elif [[ $BUILDER == "virtualbox-vagrant" ]]; then

		if [[ -d $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/vagrant ]]; then
		  echo "output directory exists we need to remove it"
		  rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/vagrant/*
		  rmdir $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/vagrant
		fi

		if [[ -d $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/virtualbox ]]; then
		  echo "output directory exists we need to remove it"
		  rm $PACKER_ARTIFACTS_DIR/$PLATFORM/$ARTIFACT_FOLDERNAME/virtualbox/*
		  rmdir $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/virtualbox
		fi
	elif [ $BUILDER == "virtualbox-vdi" ] || [ $BUILDER == "virtualbox-iso" ]; then

		if [[ -d $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/virtualbox-vdi ]]; then
		  echo "output directory exists we need to remove it"
		  rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/virtualbox/*.vdi
		  rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/virtualbox-vdi/.*
		  rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/virtualbox-vdi/*
		  rmdir $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/virtualbox-vdi
		fi

	elif [[ $BUILDER == "virtualbox-qemu" ]]; then

		if [[ -d $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/virtualbox-qemu ]]; then
		  echo "output directory exists we need to remove it"
		  rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/virtualbox-qemu/*
		  rmdir $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/virtualbox-qemu
		fi

	elif [[ $BUILDER == "kvm" ]]; then

		if [[ -d $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER ]]; then
		  echo "output directory exists we need to remove it"
		  sudo chmod -Rf 777 $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/
		  rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/*
		  rmdir $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER
		fi

	elif [[ $BUILDER == "xen" ]]; then

		if [ -z "$GOPATH" ]; then
			echo "If you want to build for xen you need to set the GOPATH environment variable and point it at your GO work directory like HOME/work"
			exit 1
		fi

		if [[ -d $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER ]]; then
		  echo "output directory exists we need to remove it"
		  sudo rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/*
		  rmdir $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER
		fi

	elif [[ $BUILDER == "ovm" ]]; then

		if [[ -d $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER ]]; then
		  echo "output directory exists we need to remove it"
		  sudo rm $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/*
		  rmdir $PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER
		fi

	else

		echo "Not removing any directories or files for $BUILDER"

	fi

	ORIGINAL_DIR=$(pwd)
	echo "original directory: $ORIGINAL_DIR"

	cd $PACKER_TEMPLATE_DIR/../..
	GIT_DIR=$(pwd)
	echo "GIT_DIR: $GIT_DIR"
	GIT_HASH=$(git --git-dir=$GIT_DIR/.git/ log -n 1 --pretty=format:"%H")
	echo "GIT_HASH: $GIT_HASH"

	cd $PACKER_TEMPLATE_DIR/

	echo "generating $BUILDER build"

	export PACKER_LOG=1

	if [[ $BUILDER == "virtualbox-qemu" ]]; then

#		PACKER_LOG=1 packer build -parallel=false -only=virtualbox-qemu -var "git_hash=$GIT_HASH" -var "morph_build_version=$MORPH_BUILD_VERSION" -var "base_image=$BASE_IMAGE" -var "image_arch=$ARCH" -var-file=$PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json $PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json

		packerCmd="groovy ../../morpheus-library -template=templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json -var-file=templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json -only=$BUILDER -parallel=false -var \"git_hash=$GIT_HASH\""
		echo "packerCmd = $packerCmd"
		eval $packerCmd

	elif [[ $BUILDER == "kvm" ]]; then

#		PACKER_LOG=1 packer build -parallel=false -only=$BUILDER -var "git_hash=$GIT_HASH" -var "morph_build_version=$MORPH_BUILD_VERSION" -var "base_image=$BASE_IMAGE" -var "image_arch=$ARCH" -var-file=$PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json $PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json

		packerCmd="groovy ../../morpheus-library -template=templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json -var-file=templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json -only=$BUILDER -parallel=false -var \"git_hash=$GIT_HASH\""
		echo "packerCmd = $packerCmd"
		eval $packerCmd

	elif [[ $BUILDER == "vmware" ]]; then
#		echo "packer template: $PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json $PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json"

#		PACKER_LOG=1 packer build -only=$BUILDER -var "git_hash=$GIT_HASH" -var "morph_build_version=$MORPH_BUILD_VERSION" -var "base_image=$BASE_IMAGE" -var "image_arch=$ARCH" -var-file=$PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json $PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json

		packerCmd="groovy ../../morpheus-library -template=templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json -var-file=templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json -only=$BUILDER -var \"git_hash=$GIT_HASH\""
		echo "packerCmd = $packerCmd"
		eval $packerCmd

	elif [[ $BUILDER == "amazon" ]]; then

#		PACKER_LOG=1 packer build -only=$BUILDER -var "git_hash=$GIT_HASH" -var "morph_build_version=$MORPH_BUILD_VERSION" -var "base_image=$BASE_IMAGE" -var "image_arch=$ARCH" -var-file=$PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json $PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json

		packerCmd="groovy ../../morpheus-library -template=templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json -var-file=templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json -only=$BUILDER -parallel=false -var \"git_hash=$GIT_HASH\""
		echo "packerCmd = $packerCmd"
		eval $packerCmd

	elif [[ $BUILDER == "xen" ]]; then

		if [ -z "$GOPATH" ]; then
			echo "If you want to build for xen you need to set the GOPATH environment variable and point it at your GO work directory like HOME/work"
			exit 1
		fi

		PACKER_LOG=1 $GOPATH/bin/packer build -only=$BUILDER -var "git_hash=$GIT_HASH" -var "morph_build_version=$MORPH_BUILD_VERSION" -var "base_image=$BASE_IMAGE" -var "image_arch=$ARCH" -var-file=$PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json $PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json

	elif [[ $BUILDER == "virtualbox-vdi" ]]; then
#		echo "$PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json $PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json"
#		PACKER_LOG=1 packer build -parallel=false -only=virtualbox-vdi -var "git_hash=$GIT_HASH" -var "morph_build_version=$MORPH_BUILD_VERSION" -var "base_image=$BASE_IMAGE" -var "image_arch=$ARCH" -var-file=$PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json $PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json
		
		packerCmd="groovy ../../morpheus-library -template=templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json -var-file=templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json -only=virtualbox-vdi -parallel=false -var \"git_hash=$GIT_HASH\""
		echo "packerCmd = $packerCmd"
		eval $packerCmd

	elif [[ $BUILDER == "ovm" ]]; then

		sudo PACKER_LOG=1 packer build -parallel=false -only=$BUILDER -var "git_hash=$GIT_HASH" -var "morph_build_version=$MORPH_BUILD_VERSION" -var "base_image=$BASE_IMAGE" -var "image_arch=$ARCH" -var-file=$PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$INSTANCE_VERSION$PACKER_TEMPLATE_VARIABLE_SUFFIX.json $PACKER_TEMPLATE_DIR/templates/$INSTANCE_TYPE/$BASE_OS/$INSTANCE_TYPE-$PACKER_TEMPLATE_BASE_SUFFIX.json

		cd "$PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER/"
		OUTPUT_BASE_DIR="$PACKER_ARTIFACTS_DIR/$ARTIFACT_FOLDERNAME/$BUILDER"

		echo "OUTPUT_BASE_DIR: $OUTPUT_BASE_DIR"

		cd "$OUTPUT_BASE_DIR"

		echo "pwd: $(pwd)"

		echo "Changing permissions to $OUTPUT_BASE_DIR"

		sudo chmod -Rf 777 $OUTPUT_BASE_DIR

		TMP_RAW_FILE=(${prefix}*.raw)

		echo "Backing up TMP_RAW_FILE: $TMP_RAW_FILE"

		cp $TMP_RAW_FILE $TMP_RAW_FILE.orig

		echo "vhd tar file ready"

	else

		echo "builder not recognized so did not run packer"

	fi

	echo "packer build done"
	echo "ORIGINAL_DIR: $ORIGINAL_DIR"
	cd "$ORIGINAL_DIR"
fi
