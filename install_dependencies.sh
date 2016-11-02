#!/bin/bash

set -x
set -e

start_dir=$(pwd)

BLAST_VERSION="2.5.0"
BLAST_DOWNLOAD_FILENAME="ncbi-blast-${BLAST_VERSION}+-x64-linux.tar.gz"
BLAST_PLUS_URL="ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/${BLAST_VERSION}/${BLAST_DOWNLOAD_FILENAME}"

# Make an install location
if [ ! -d 'build' ]; then
  mkdir build
fi
cd build

# Download blast
build_dir=$(pwd)
BLAST_DOWNLOAD_PATH="$(pwd)/${BLAST_DOWNLOAD_FILENAME}"

if [ -e "$BLAST_DOWNLOAD_PATH" ]; then
  echo "Skipping download of $BLAST_PLUS_URL, $BLAST_DOWNLOAD_PATH already exists"
else
  echo "Downloading $BLAST_PLUS_URL to $BLAST_DOWNLOAD_PATH"
  wget $BLAST_PLUS_URL -O $BLAST_DOWNLOAD_PATH
fi

# Untar blast
BLAST_BUILD_DIR="$(pwd)/ncbi-blast-${BLAST_VERSION}+"

if [ -d "$BLAST_BUILD_DIR" ]; then
  echo "Blast already untarred to $BLAST_BUILD_DIR, skipping"
else
  echo "Untarring blast to $BLAST_BUILD_DIR"
  tar xzvf $BLAST_DOWNLOAD_PATH
fi

cd $BLAST_BUILD_DIR

# Add blast to PATH
BLAST_BIN_DIR="$(pwd)/bin"
update_path () {
  new_dir=$1
  if [[ ! "$PATH" =~ (^|:)"${new_dir}"(:|$) ]]; then
    export PATH=${new_dir}:${PATH}
  fi
}

export PATH
update_path $BLAST_BIN_DIR

# Install Dist::Zilla
if [ "$TRAVIS" = 'true' ]; then
  echo "Using Travis's apt plugin"
else
  sudo apt-get update -q
  sudo apt-get install -y -q libssl-dev \
                             libxml2 \
                             libxml2-dev \
                             zlibc \
                             zlib1g \
                             zlib1g-dev
fi

cpanm Pod::Elemental::Transformer::List \
      XML::LibXML \
      Dist::Zilla

# Install MLST_check (so that we can download some databases)
cd $start_dir
dzil authordeps --missing | cpanm
dzil install

cd $start_dir

set +e
set +x
