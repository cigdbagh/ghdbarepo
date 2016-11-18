#!/bin/sh
# Name     :  rman_incremental_merge_approd.sh 
# Author   :  Ganga Pisari
# Created  :  11/02/16
# Desc     :  Unix Shell script is for full database level ZERO backup on Sunday and incremental level ONE backups on all other days#             of the week using RMAN with recovery catalog.
#          :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx

############################################################
#            MAIN                
############################################################
#################################
### Set environment variables ###
#################################
ORACLE_SID="approd1";export ORACLE_SID
DBNAME=${ORACLE_SID};export DBNAME
DBNAME1="approd1"
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM=vt100;export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH
SCR_PATH="/db/sw/oracle/scripts/rman";export SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/rman/logs";export LOG_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
PWD=`sh ${PWD_PATH}/getdopnsys1.sh`
#PWD2=rman
PWD2=`sh ${PWD_PATH}/getdopn1.sh`
##*##PWD2=`sh ${PWD_PATH}/getdopnhp7.sh`
SCHEMA_TGT=sys;export SCHEMA_TGT
SCHEMA_RCAT=rman;export SCHEMA_RCAT
CATDB="foxtrot";export CATDB
ORA_OWNER="oracle";export ORA_OWNER
TODAY=`date "+%m%d%Y"`
DAY=`date "+%A"`
##END_JOB="`date`"
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`

###########################
###Parameter for mailing ##
###########################
MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh` 
#MAIL_LOG_TO_DBA="gpisari@ciginsurance.com "
MAIL_LOG_TO_USER=`sh ${PWD_PATH}/mail_log_to_dba.sh` 
########################
###Log file paramters###
########################

LOGMODE="${LOG_PATH}/logmode.log";export LOGMODE
LOGTXT="${LOG_PATH}/logmode.txt";export LOGTXT
DAY_OF_WEEK="${LOG_PATH}/logday.log";export DAY_OF_WEEK 
LOGTXT1="${LOG_PATH}/logday.txt";export LOGTXT1
LOGFILE1="${LOG_PATH}"/"rman_incr_merge_${DBNAME}_${DAY}_${TODAY}.log";export LOGFILE1
TXTFILE1="${LOG_PATH}"/"rman_incr_merge_${DBNAME}_${DAY}_${TODAY}.txt";export TXTFILE1
LOGDIR="${LOG_PATH}"/"rman_incr_merge_${DBNAME}_${DAY}_${TODAY}.log"
JOBNAME="rman_incremental_merge"

echo " Starting ${JOBNAME} of .... ${DBNAME1}" 

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# funct_verify(): Verify that database is online                  # 
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: 
STATUS=`ps -fu ${ORA_OWNER} |grep -v grep| grep ora_pmon_${DBNAME1}`
if [ $? != 0 ];then 
##funct_verify() {
echo "Database is down for given SID($DBNAME1). Can't perform rmanbackup"
     exit 1
fi
    echo "${JOBNAME}: Database is up.  Continuing." 
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# funct_chk_dblogmode(): Check DB log mode                     # 
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sqlplus -S << END_SQL
sys/${PWD}@$DBNAME as sysdba

set heading off  feedback off
spool $LOGMODE
select log_mode from v\$database;
exit
spool off;
END_SQL
pg ${LOGMODE}|grep "ARCHIVELOG" > ${LOGTXT}
if [ -f ${LOGTXT} ]
   then
   RUN_CHECK=`cut -c1-10 ${LOGTXT}`
   if [ "${RUN_CHECK}" != "ARCHIVELOG" ]
      then
      ####echo "*********** Error occurred *********"
      mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOGFILE1}"
      exit 1
   fi
fi
if [ "${DAY}" = "Sunday" ]
      then
      ##==================##
      ##Level ZERO backup ##
      ##==================##
rman <<EOF > ${LOG_PATH}/rman_incr_merge_${DBNAME}_${DAY}_${TODAY}.log
      connect target ${SCHEMA_TGT}/${PWD}@$DBNAME;
      connect catalog ${SCHEMA_RCAT}/${PWD2}@${CATDB};
      show all;
      report schema;
##      list copy tag weekly;
      ##*##delete copy tag weekly;
      ##delete force noprompt copy tag weekly;
      delete force noprompt archivelog all backed up 2 times to sbt_tape;
      delete noprompt obsolete;
      run {backup  incremental level 0 tag=weekly database; }
      run { backup archivelog all ;
	backup current controlfile;
	backup spfile;
	 }
      crosscheck backup;
      #restore controlfile validate;
      #restore tablespace SYSTEM validate;
      ##*##restore archivelog all validate;
      list backup of database;
      list backupset summary;
      report unrecoverable;
      report need backup;
### New line added to crosscheck the backups
      report obsolete;
      ##*##delete noprompt obsolete;
      delete force noprompt archivelog all backed up 2 times to sbt_tape;
EOF
     elif [ "${DAY}" = "Wednesday" ] 
      then 
      ##=============================##
      ## Level ONE Cumulative backup ##
      ##=============================##
rman <<EOF > ${LOG_PATH}/rman_incr_merge_${DBNAME}_${DAY}_${TODAY}.log
      connect target ${SCHEMA_TGT}/${PWD}@$DBNAME ;
      connect catalog ${SCHEMA_RCAT}/${PWD2}@${CATDB};
      show all;
      report schema;
      delete force noprompt archivelog all backed up 2 times to sbt_tape;
      delete noprompt obsolete;
      run {  backup incremental level 1 cumulative for recover  of tag weekly  database; }
      run {
      backup archivelog all ;
      backup current controlfile; 
        backup spfile;
}
      crosscheck backup;
      #restore controlfile validate;
      #restore tablespace SYSTEM validate;
      ##*##restore archivelog all validate;
      list backup of database;
      list backupset summary;
      report unrecoverable;
      report need backup;
### New line added to crosscheck the backups
 ##     crosscheck copy;
      report obsolete;
      ##*##delete noprompt obsolete;
     delete force noprompt archivelog all backed up 2 times to sbt_tape;
EOF
   else
      ##==================##
      ## Level ONE backup ##
      ##==================##
rman <<EOF > ${LOG_PATH}/rman_incr_merge_${DBNAME}_${DAY}_${TODAY}.log
      connect target ${SCHEMA_TGT}/${PWD}@$DBNAME;
      connect catalog ${SCHEMA_RCAT}/${PWD2}@${CATDB};
      show all;
##      list copy tag weekly;
      report schema;
      delete force noprompt archivelog all backed up 2 times to sbt_tape;
      delete noprompt obsolete;
      run {  backup incremental level 1 cumulative for recover of  tag weekly  database; }
      run {
      backup archivelog all ;
      backup current controlfile; 
        backup spfile;
}
#      crosscheck backup;
      #restore controlfile validate;
      #restore tablespace SYSTEM validate;
      ##*##restore archivelog all validate;
      list backup of database;
      list backupset summary;
      report unrecoverable;
      report need backup;
### New line added to crosscheck the backups
      report obsolete;
      ##*##delete noprompt obsolete;
      delete force noprompt archivelog all backed up 2 times to sbt_tape;
EOF
fi
#########################################
###Error checking for Rman backup job ###
#########################################

if [ -f ${TXTFILE1} ]; then
      rm ${TXTFILE1}
fi

pg ${LOGFILE1}|grep ORA- > ${TXTFILE1}
pg ${LOGFILE1}|grep RMAN- >> ${TXTFILE1}

if [ -f ${TXTFILE1} ]; then
       BY_CNT=`ls -ltr ${TXTFILE1}|awk '{ print $5 }'`
       if [ ${BY_CNT} != 0 ]; then
        MAIL_LOG_SUB1="Rman Incr Merge Backup : ${U_DBNAME} RMAN Backup Failed  at `date` " 
        mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOGFILE1}"
          else
        MAIL_LOG_SUB2="Rman Incr Merge Backup : ${U_DBNAME} RMAN Backup Succeeded at `date` "
        mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_DBA}" < "${LOGFILE1}"
          exit 1
    fi
fi
