# ! /usr/bin/sh
# Name     :  pkg_ca_dmv_err.sh
# Author   :  ShashiPavan
# created  :  04/12/04
# Desc     :  This particular shell script is used to run pkg_ca_dmv_notify_readin.sh and move the error log with 
#             current date. This script runs from Monday-Friday at 21:35.
# Modified :  04/12/04 - Marimer Panganiban - xxxxxxxxxx
#          :  02/10/05 - Sasi Sivadasan - Scripts are rewrote to include scripting standards and desc.
#	   :  03/20/06 - kavita		- MAIL_LOG_TO_DBA & changed the path from 8.1.6 - 11.1.0/db_1
#          :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

SCR_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES";export SCR_PATH

DBNAME=${ORACLE_SID}
INT_PATH="/db/data/a3/oracle/${DBNAME}/interfaces/vin";export INT_PATH

TODAY=`date "+%Y%b%d"`

ERR_FILE1="${INT_PATH}"/"Err"
ERR_FILE2="${INT_PATH}"/"Err${TODAY}"
REMATCH_FILE1="${INT_PATH}"/"rematch"
REMATCH_FILE2="${INT_PATH}"/"rematch${TODAY}"

if  [${ERR_FILE1} ] || [ ${REMATCH_FILE1} ]
  then
  sh ${SCR_PATH}/pkg_ca_dmv_notify_readin.sh
  mv ${ERR_FILE1} ${ERR_FILE2}
  mv ${REMATCH_FILE1} ${REMATCH_FILE2}
  exit 1
  else
  echo "bye bye"
  exit 1
fi

