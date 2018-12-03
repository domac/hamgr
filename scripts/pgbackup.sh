#!/bin/sh  

# */5 * * * *
# 0 5 * * *

PGUSER=postgres
PGBIN=/data/service/pgsql_10.0/bin
BACKUPDIR=/data/pg10/backups

BACKUPDATE=`date +%Y%m%d%H%M%S`
BACKUPSUBDIR=$BACKUPDIR/$BACKUPDATE
BACKUPLOG=$BACKUPDIR/backup.log

mkdir -p $BACKUPDIR
mkdir -p $BACKUPSUBDIR

chown -R postgres:postgres $BACKUPDIR
chown -R postgres:postgres $BACKUPSUBDIR

su - $PGUSER -c "$PGBIN/pg_basebackup -Ft -Pv -Xf -z -Z5  -U postgres -p 25432 -D $BACKUPSUBDIR"
su - $PGUSER -c "echo 'success backup on $BACKUPDATE' >> $BACKUPLOG"

# 清理历史备份,只保留10天
find $BACKUPDIR/2* -type d -atime +10 | xargs rm -rf 