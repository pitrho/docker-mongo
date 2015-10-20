#!/bin/bash

REDIS_DATA_DIR=${REDIS_DATA_DIR:=/var/lib/redis}

[ -z "${S3_BUCKET}" ] && { echo "=> S3_BUCKET cannot be empty" && exit 1; }
[ -z "${AWS_ACCESS_KEY_ID}" ] && { echo "=> AWS_ACCESS_KEY_ID cannot be empty" && exit 1; }
[ -z "${AWS_SECRET_ACCESS_KEY}" ] && { echo "=> AWS_SECRET_ACCESS_KEY cannot be empty" && exit 1; }
[ -z "${AWS_DEFAULT_REGION}" ] && { echo "=> AWS_DEFAULT_REGION cannot be empty" && exit 1; }

BACK_ONLY_MASTER=${BACKUP_ONLY_MASTER:="false"}
MAX_BACKUPS=${MAX_BACKUPS:=30}
BACKUP_NAME=$( [ ${MONGO_DB} ] && echo "${MONGO_DB}_`date +"%m%d%Y_%H%M%S"`.tar.gz" || echo "mongodb_`date +"%m%d%Y_%H%M%S"`.tar.gz" )
BACKUP_DIR=/tmp/backup/

# Check if we're told to back up onl the master. If so, and we're not the master
# then exit
if [ "$BACK_ONLY_MASTER" = "true" ]; then
  IS_MASTER=`mongo --quiet --eval 'db.isMaster().ismaster'`

  if [ $IS_MASTER = false ]; then
      echo "Not master. Exiting ..."
      exit 0
  fi
fi

echo "=> Backup started ..."

# First, make sure the that the S3_BUCKET path exists
#
count=`/usr/bin/aws s3 ls s3://$S3_BUCKET | wc -l`

if [[ $count -eq 0 ]]; then
  echo "Path $S3_BUCKET not found."
  exit 1
fi

# Dump the mongodb data
rm -rf $BACKUP_DIR
mkdir $BACKUP_DIR
if [ -z "$MONGO_DB" ]; then
    mongodump --out $BACKUP_DIR
else
    mongodump --db $MONGO_DB --out $BACKUP_DIR
fi

cd /tmp
tar -zcf $BACKUP_NAME $BACKUP_DIR

# Copy the backup to the S3 bucket
echo "Copying $BACKUP_NAME to S3 ..."
S3_FILE_PATH="s3://$S3_BUCKET/$BACKUP_NAME"
/usr/bin/aws s3 cp $BACKUP_NAME $S3_FILE_PATH


echo "Removing old databse backup files ..."
files=($(aws s3 ls s3://$S3_BUCKET | awk '{print $4}'))
count=${#files[@]}
diff=`expr $count - $MAX_BACKUPS`
if [[ $diff -gt 0 ]]; then
  while [[ $diff -gt 0 ]]; do
    i=`expr $diff - 1`
    file=${files[$i]}
    /usr/bin/aws s3 rm s3://$S3_BUCKET/$file
    let diff=diff-1
  done
fi

# Clean up
rm $BACKUP_NAME
cd ..
rm -rf $BACKUP_DIR

echo "=> Backup done"
