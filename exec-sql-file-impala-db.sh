#!/bin/bash
#########################################
# Script executing SQL file on Impala DB
#########################################
set -e
export SQL_FILE_NAME=$1
export IMPALA_DB_NAME=$2

export DATE=`date +%Y%m%d_%H%M%S`
export HOME_DIR=`cd;pwd`
export CURRDIR=${HOME_DIR}
export MAIN_LOG=${CURRDIR}/logs/Execute_SQL_File_${IMPALA_DB_NAME}_${DATE}.log
mkdir -p ${CURRDIR}/logs

Init_Validation()
{
  if [[ -z ${SQL_FILE_NAME} || -z ${IMPALA_DB_NAME}  ]]
  then
    echo >> ${MAIN_LOG}
    echo "USAGE : `basename $0` <SQL File Name> <Impala DB Name> " >> ${MAIN_LOG}
    echo -e "\nExample: `basename $0` tst.sql impala_db1 \n " >> ${MAIN_LOG}
    exit 1
   fi

   # Validate SQL File Exist on Script directory
   if [[ ! -e ${CURRDIR}/${SQL_FILE_NAME} ]]
   then
     echo "######################################################" >> ${MAIN_LOG}
     echo "SQL File Name ${CURRDIR}/${SQL_FILE_NAME} Not Found" >> ${MAIN_LOG}
     echo "Exiting.." >> ${MAIN_LOG}
     echo "######################################################" >> ${MAIN_LOG}
   fi

}

Execute_SQL_File()
{
  source ~/.bashrc; impala-shell -d ${IMPALA_DB_NAME} -f ${SQL_FILE_NAME} >> ${MAIN_LOG}
}

###Main###
Init_Validation
Execute_SQL_File
