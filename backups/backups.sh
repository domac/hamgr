#!/bin/sh

#星期几
BACKUP_WEEKDAY=3 
#几时
BACKUP_HOUR=3 
#几分
BACKUP_MIN=30

#当前目录
CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

#数据目录
PROJECT=/data/services/pcmgr_enterprise
#备份路径
BACKUPDIR=$PROJECT/backups
#下载接口
DOWNLOAD_API=http://10.14.12.8:10080/base.tar.gz
BACKUPDATE=`date +%Y%m%d`
#备份目录
BACKUPSUBDIR=$BACKUPDIR/$BACKUPDATE
BACKUPLOG=$BACKUPDIR/backup.log


mkdir -p $BACKUPDIR
mkdir -p $BACKUPSUBDIR

echo "curr dir : $CURRENT_DIR"

#写日志
function write_log(){
    [ -f $BACKUPLOG ] || touch $BACKUPLOG
    level=$1
    msg=$2
    case $level in
    1) log_lel='DEBUG'
    ;;
    2) log_lel='INFO'
    ;;
    3) log_lel='WARMING'
    ;;
    4) log_lel='ERROR'
    ;;
    esac
    echo -e "$log_lel $(date '+%y/%m/%d %H:%M:%S') backups.sh $msg" | tee -a $BACKUPLOG  
}

#备份函数
function backup()
{
    #如果已经存在当天的备份，删除它已作更新
    if [ -d $BACKUPSUBDIR ];then
        write_log 2 "remove last backup: $BACKUPSUBDIR"
        rm -rf $BACKUPSUBDIR
    fi

    mkdir -p $BACKUPSUBDIR

    cd $BACKUPSUBDIR && wget $DOWNLOAD_API

    # 清理历史备份,只保留最近两个星期的文件
    find $BACKUPDIR/2*  -maxdepth 0 -type d -mtime +13 | xargs rm -rf
    write_log 2 "remote backups task success"   
}


function initbackup()
{
    mkdir -p $BACKUPDIR

    rm -rf $BACKUPDIR/backups.sh
    cp -r $CURRENT_DIR/backups.sh $BACKUPDIR
    chmod +x $BACKUPDIR/backups.sh

    if [ ! -f "/var/spool/cron/root" ]; then
        touch /var/spool/cron/root
    fi 
    sed -i '/pcmgr_enterprise/d'  /var/spool/cron/root

    write_log 2 "init db backups cron start"
    if [ `grep -v '^\s*#' /var/spool/cron/root |grep -c '/data/services/pcmgr_enterprise/backups'` -eq 0 ]; then
        echo "$BACKUP_MIN $BACKUP_HOUR * * $BACKUP_WEEKDAY sh /data/services/pcmgr_enterprise/backups/backups.sh start" >> /var/spool/cron/root
    fi
    write_log 2 "init db backups cron finish"
}

# Parse command line parameters.
case $1 in
  init)
	echo "init backup env"
    initbackup
    echo "ok"
	;;
  start)
	echo "start backup task"
	backup
    echo "ok"
	;;
  *)
	# Print help
	echo "Usage: $0 {init|start}" 1>&2
	exit 1
	;;
esac

exit 0
