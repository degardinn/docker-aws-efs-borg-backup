#!/bin/sh -e

export BORG_PASSPHRASE=${1:?'Missing passphrase'}
SOURCE=$2
BACKUP=$3
REPO=${4:-'borg'}
BORG_RETENTION_DAILY=${5:-7}
BORG_RETENTION_WEEKLY=${6:-4}
BORG_RETENTION_MONTHLY=${7:-6}

if [ -z $SOURCE ]; then
    echo "** Source: nothing specified (mounted volume?)"
else
    echo "** Source: EFS '$EFS'"
    mount -t nfs4 -o nfsvers=4.1,ro,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $SOURCE:/ /mnt/source
fi

if [ -z $3 ]; then
    echo "** Backup: nothing specified (mounted volume?)"
else
    echo "** Backup: EFS '$EFS'"
    mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $BACKUP:/ /mnt/backup
fi

DIRECTORIES=$(find /mnt/source/* -maxdepth 0 -type d -print)
REPOSITORIES="/mnt/backup/$REPO"
mkdir -p $REPOSITORIES

for DIRECTORY in $DIRECTORIES; do
    DIR=${DIRECTORY##/*/}
    REPOSITORY="$REPOSITORIES/$DIR"
    if [ ! -d $REPOSITORY ];then
        echo "** Repository $REPOSITORY: init"
        borg init $REPOSITORY
    else
        echo "** Repository $REPOSITORY: break-lock and check"
        borg break-lock $REPOSITORY
        borg check $REPOSITORY
    fi
    echo "** Repository $REPOSITORY: archiving and pruning"
    borg create -v --list --stats --compression zlib,8 $REPOSITORY::'{now:%Y-%m-%d}' $DIRECTORY && \
    borg prune -v --list $REPOSITORY --keep-daily=$BORG_RETENTION_DAILY --keep-weekly=$BORG_RETENTION_WEEKLY --keep-monthly=$BORG_RETENTION_MONTHLY &
    echo "** Repository $REPOSITORY: done"
done

wait
echo "** All done"