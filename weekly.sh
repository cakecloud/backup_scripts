#!/bin/bash
ENV=/root/.bashrc
#PLEASE CHANGE START IN 70 LINE ( "$DAY" = "4" )  Uznat podrobnee - line 32
#source /root/.keychain/$HOSTNAME-sh
# A Simple Shell Script to Backup Red Hat / CentOS / Fedora / Debian / Ubuntu Apache Webserver and SQL Database
# Path to backup directories
#DIRS=""
########### Common Settings ###########

# Paths for binary files
TAR="/bin/tar"
#PGDUMP="/usr/bin/pg_dump"
MYSQLDUMP="/usr/bin/mysqldump"
GZIP="/bin/gzip"
SCP="/usr/bin/scp"
SSH="/usr/bin/ssh"
LOGGER="/bin/logger"
FIND="/usr/bin/find"
#RMFIND="/bin/find"

EXCLUDE_CONF="/root/backup/exclude.files.conf"

# SSH / SFTP settings
SSHSERVER="198.50.50.50" # your remote ssh server
SSHUSER="bksyftp"                # username   
SSHPORT="51052"

# Store todays date
NOW=$(date +"%F"_"%H"-"%M")
BKDIR="daily"

#Get the number of the day of the week
DAY=$(date +%u)

########### END Common Settings ###########

########### xxx.com Backup ###########
DOMAIN="xxx.com"
SNAPSHOT_FILE_0="/root/backup/$DOMAIN/$BKDIR/snapshot_0.snar"
SNAPSHOT_FILE="/root/backup/$DOMAIN/$BKDIR/snapshot.snar"
# Set MySQL username and password
MYSQLDB="xxx_db"
MYSQLUSER="xxx_adm"
MYSQLPASSWORD="akjshd^&%AadjhbvjhHV"

CDDIR="/www/$DOMAIN/"
TARDIR="public_html"

# Backup names
BFILE="$DOMAIN.$NOW.tar.gz"
MFILE="$DOMAIN.$NOW.mysql.sq.gz"

# Store backup path
BACKUP="/root/backup/$DOMAIN/$BKDIR"

# Remote SSH backup dir
SSHDUMPDIR="$DOMAIN/${BKDIR}"    # remote ssh server directory to store dumps

# make sure backup directory exists
[ ! -d $BACKUP ] && mkdir -p ${BACKUP}
 
# Log backup start time in /var/log/messages
$LOGGER "$0: *** ${DOMAIN} ${BKDIR} Backup started @ $(date) ***"
 

#Removing the current metadata
rm -rf ${SNAPSHOT_FILE}

#If it's Sunday - we delete the initial metadata file and archives
if [ "$DAY" = "4" ]; then
 NUM="0"
 rm -rf ${SNAPSHOT_FILE_0}
 rm -rf ${BACKUP}/${DOMAIN}*
 rm -rf ${BACKUP}/${DOMAIN}*
 $SSH -p ${SSHPORT} ${SSHUSER}@${SSHSERVER} "rm -rf ${DOMAIN}/${BKDIR}/*"

else
 NUM="$DAY"
fi

#If there is initial metadata, copy it
if [ -f ${SNAPSHOT_FILE_0} ]; then 
 cp ${SNAPSHOT_FILE_0} ${SNAPSHOT_FILE}
fi

# Backup websever dirs
#$TAR -zcvf ${BACKUP}/${BFILE} "${DIRS}"
$TAR  --exclude-from=${EXCLUDE_CONF} --listed-incremental=${SNAPSHOT_FILE} -zcvf ${BACKUP}/${BFILE} -C ${CDDIR} "${TARDIR}"
 

#If it's Sunday, create an initial copy of the metadata
if [ "$DAY" = "4" ]; then 
 cp ${SNAPSHOT_FILE} ${SNAPSHOT_FILE_0}
fi

# Backup PgSQL
#$PGDUMP -x -D -U${PGSQLUSER} | $GZIP -c > ${BACKUP}/${PFILE}
  


#############

# Backup MySQL  
$MYSQLDUMP  -u ${MYSQLUSER} -h localhost -p${MYSQLPASSWORD} ${MYSQLDB} | $GZIP -9 > ${BACKUP}/${MFILE}
 

#############


# Dump all local files to failsafe remote UNIX ssh server / home server
#$SSH ${SSHUSER}@${SSHSERVER} mkdir -p ${SSHDUMPDIR}
#$SSH ${SSHUSER}@${SSHSERVER}

$SCP -P ${SSHPORT} -C -o 'CompressionLevel 9' -o 'IPQoS throughput' -c arcfour ${BACKUP}/${BFILE} ${SSHUSER}@${SSHSERVER}:${SSHDUMPDIR}/${BFILE}
$SCP -P ${SSHPORT} -C -o 'CompressionLevel 9' -o 'IPQoS throughput' -c arcfour ${BACKUP}/${MFILE} ${SSHUSER}@${SSHSERVER}:${SSHDUMPDIR}/${MFILE}
$SCP -P ${SSHPORT} -C -o 'CompressionLevel 9' -o 'IPQoS throughput' -c arcfour ${SNAPSHOT_FILE} ${SSHUSER}@${SSHSERVER}:${SSHDUMPDIR}/
$SCP -P ${SSHPORT} -C -o 'CompressionLevel 9' -o 'IPQoS throughput' -c arcfour ${SNAPSHOT_FILE_0} ${SSHUSER}@${SSHSERVER}:${SSHDUMPDIR}/

# Log backup end time in /var/log/messages
$LOGGER "$0: *** ${DOMAIN} ${BKDIR} Backup Ended @ $(date) ***"

########### END xxx.com Backup ###########


