#!/bin/sh  

# 0 5 * * * sh /usr/local/bin/pgbackup.sh
# 0 5 * * * . /etc/profile.d/pg.sh; /data/services/postgres/pg_backup.sh >> /data/services/postgres/pg_backup.log 2>&1

PGUSER=postgres
PGHOME=/data/services/postgres
PGBIN=/data/services/postgres/bin
BACKUPDIR=/data/services/postgres/backups

#su - $PGUSER -c "export LD_LIBRARY_PATH=$PGHOME/lib:/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib"

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