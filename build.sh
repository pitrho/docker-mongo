#!/bin/bash

MONGO_VERSION=3.0.7
IMAGE_TAG="pitrho/mongo"

# Custom die function.
#
die() { echo >&2 -e "\nRUN ERROR: $@\n"; exit 1; }

# Parse the command line flags.
#
while getopts "v:t:" opt; do
  case $opt in
    t)
      IMAGE_TAG=${OPTARG}
      ;;

    v)
      MONGO_VERSION=${OPTARG}
      ;;

    \?)
      die "Invalid option: -$OPTARG"
      ;;
  esac
done

MONGO_MAJOR=`echo $MONGO_VERSION | cut -d. -f1 -f2`

MONGO_REPO="deb http:\/\/repo.mongodb.org\/apt\/ubuntu trusty\/mongodb-org\/$MONGO_MAJOR multiverse"
if [ `echo $MONGO_VERSION | cut -d. -f1` -ne 3 ]; then
    MONGO_REPO="deb http:\/\/downloads-distro.mongodb.org\/repo\/ubuntu-upstart dist 10gen"
fi

rm -rf build
mkdir build
cp run.sh build/
cp enable_backups.sh build/
cp backup.sh build/
sed 's/%%MONGO_REPO%%/'"$MONGO_REPO"'/g; s/%%MONGO_VERSION%%/'"$MONGO_VERSION"'/g' Dockerfile.tmpl > build/Dockerfile

docker build -t="${IMAGE_TAG}" build/

rm -rf build
