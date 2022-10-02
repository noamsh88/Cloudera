#!/bin/bash
####################################################################################################################################
#Script is copying cloudera logs directories per required service or to all services and pack them into gzip tar file
####################################################################################################################################
export SERVICE_NAME=$1
export LAST_N_LINES=$2
####################################################################################################################################
export DATE=`date +%Y%m%d_%H%M%S`
export CURRDIR=`pwd`
export MAIN_LOG=${CURRDIR}/logs/pack_cloudera_log_dirs_${SERVICE_NAME}_${DATE}.log
export SERVICE_NAME=`echo ${SERVICE_NAME} | tr '[:upper:]'  '[:lower:]'`
export PACK_DIR=${CURRDIR}/pack-cloudera-log-dirs-`hostname`-${SERVICE_NAME}-${DATE}
#Set Log directories for each service
. ./pack-cloudera-log-dirs.par
####################################################################################################################################

Init_Validation()
{
  #Create logs directory in case not exist
  if [[ ! -d ${CURRDIR}/logs ]]
  then
    mkdir -p ${CURRDIR}/logs
  fi

  if [[ -z ${SERVICE_NAME} ]]
  then
    echo | tee -a ${MAIN_LOG}
    echo "USAGE : `basename $0` <SERVICE NAME or ALL> " | tee -a ${MAIN_LOG}
    echo -e "\nExample: `basename $0` impala \n "   | tee -a ${MAIN_LOG}
    echo -e "\nExample: `basename $0` all \n "   | tee -a ${MAIN_LOG}
    exit 1
  fi

  #Validate if pack-cloudera-log-dirs.par exist on script directory
  if [[ ! -e ${CURRDIR}/pack-cloudera-log-dirs.par ]]
  then
    echo "pack-cloudera-log-dirs.par file Not Found at ${CURRDIR} , please copy it" | tee -a ${MAIN_LOG}
    exit 1
  fi

  #Validate SERVICE_NAME input is correct
  if [[ ${SERVICE_NAME} -ne "all" || ${SERVICE_NAME} -ne "hdfs" || ${SERVICE_NAME} -ne "hive" || ${SERVICE_NAME} -ne "hue" || ${SERVICE_NAME} -ne "impala" || ${SERVICE_NAME} -ne "kafka" || ${SERVICE_NAME} -ne "zookeeper" || ${SERVICE_NAME} -ne "oozie" || ${SERVICE_NAME} -ne "spark" || ${SERVICE_NAME} -ne "yarn"  ]]
  then
    echo "Please enter correct Value for SERVICE_NAME parameter" | tee -a ${MAIN_LOG}
    echo "correct Values are: all/hdfs/hive/nue/impala/kafka/zookeeper/oozie/yarn/spark" | tee -a ${MAIN_LOG}
    echo "Exiting.. " | tee -a ${MAIN_LOG}
    exit 1
  fi

}

Set_LOG_DIRS()
{
  local SERVICE=$1

  case ${SERVICE} in
  hdfs)
  export LOG_DIRS=${HDFS_LOGDIRS}
  ;;
  hive)
  export LOG_DIRS=${HIVE_LOGDIRS}
  ;;
  hue)
  export LOG_DIRS=${HUE_LOGDIRS}
  ;;
  impala)
  export LOG_DIRS=${IMPALA_LOGDIRS}
  ;;
  oozie)
  export LOG_DIRS=${OOZIE_LOGDIRS}
  ;;
  spark)
  export LOG_DIRS=${SPARK_LOGDIRS}
  ;;
  yarn)
  export LOG_DIRS=${YARN_LOGDIRS}
  ;;
  kafka)
  export LOG_DIRS=${KAFKA_LOGDIRS}
  ;;
  zookeeper)
  export LOG_DIRS=${ZOOKEEPER_LOGDIRS}
  ;;
  cloudera)
  export LOG_DIRS=${CLOUDERA_LOGDIRS}
  ;;
  all)
  export LOG_DIRS=${ALL_LOGDIRS}
  ;;
  esac
}

#check if all relevant logs dirs are exist on server
Validate_Log_Directories_Exist()
{
  local LOG_DIRS=$1

  for DIR_NAME in ${LOG_DIRS};do
    if [[ ! -d ${DIR_NAME} ]]
    then
      echo "#####################################################" | tee -a ${MAIN_LOG}
      echo "Directory ${DIR_NAME} Not Found" | tee -a ${MAIN_LOG}
      echo "Please set correct directory path on pack-cloudera-log-dirs.par file, Exiting.." | tee -a ${MAIN_LOG}
      echo "#####################################################" | tee -a ${MAIN_LOG}
      exit 1
    fi
  done

}

#Create pack/output directory to copy all log directories into it
Create_Pack_Directory()
{
  if [[ ${SERVICE_NAME} == "all" ]]
  then
    mkdir -p ${PACK_DIR}/hdfs
    mkdir -p ${PACK_DIR}/hue
    mkdir -p ${PACK_DIR}/hive
    mkdir -p ${PACK_DIR}/impala
    mkdir -p ${PACK_DIR}/kafka
    mkdir -p ${PACK_DIR}/oozie
    mkdir -p ${PACK_DIR}/spark
    mkdir -p ${PACK_DIR}/yarn
    mkdir -p ${PACK_DIR}/zookeeper
    #mkdir -p ${PACK_DIR}/cloudera_managment
  else
    mkdir -p ${PACK_DIR}/${SERVICE_NAME}
  fi

}

#Copy all log directories into new pack direcory according to service name or for all services
Copy_Log_Directories()
{
  echo "############      Starting Copy Cloudera Log Directories     ############" | tee -a ${MAIN_LOG}
  if [[ ${SERVICE_NAME} == "all" ]]
  then
    for SERVICE in ${SERVICE_LIST};do
      Set_LOG_DIRS ${SERVICE}
    for DIR_NAME in ${LOG_DIRS};do
      scp -r ${DIR_NAME} ${PACK_DIR}/${SERVICE}
      echo "${DIR_NAME} Directory copied to ${PACK_DIR}/${SERVICE}" | tee -a ${MAIN_LOG}
    done
  done
  else
    for DIR_NAME in ${LOG_DIRS};do
      scp -r ${DIR_NAME} ${PACK_DIR}/${SERVICE_NAME}
      echo "${DIR_NAME} Directory copied to ${PACK_DIR}/${SERVICE_NAME}" | tee -a ${MAIN_LOG}
    done
  fi
  echo "############      Finished Copying Cloudera Log Directories     ############" | tee -a ${MAIN_LOG}
  echo | tee -a ${MAIN_LOG}
}


#Shrink log files to have only last N lines
Shrink_Log_Files()
{
  echo "############      Shrinking All Log Files to have only ${LAST_N_LINES} Last Lines    ############" | tee -a ${MAIN_LOG}
  if [[ ${SERVICE_NAME} == "all" ]]
  then
    SERVICE_LOG_FILES=$(ls ${PACK_DIR}/${SERVICE_NAME}/*.log* | grep -v LAST_${LAST_N_LINES}_LINES | xargs)
    for LOG_NAME in ${SERVICE_LOG_FILES};do
      cd ${PACK_DIR}/${SERVICE_NAME}
      tail -n ${LAST_N_LINES} > ${LOG_NAME}_LAST_${LAST_N_LINES}_LINES ; rm -fr ${LOG_NAME}
    done
  done
  else
    for DIR_NAME in ${LOG_DIRS};do
      scp -r ${DIR_NAME} ${PACK_DIR}/${SERVICE_NAME}
      echo "${DIR_NAME} Directory copied to ${PACK_DIR}/${SERVICE_NAME}" | tee -a ${MAIN_LOG}
    done
  fi
  echo "############      Finished Copying Cloudera Log Directories     ############" | tee -a ${MAIN_LOG}
  echo | tee -a ${MAIN_LOG}
}

Pack_Logs_Directory()
{
  echo "############      Packing Target Directory     ############" | tee -a ${MAIN_LOG}
  echo "cd ${CURRDIR}; tar -cvf ${PACK_DIR}.tar ${PACK_DIR}; gzip ${PACK_DIR}.tar" | tee -a ${MAIN_LOG}
  echo | tee -a ${MAIN_LOG}

  cd ${CURRDIR} | tee -a ${MAIN_LOG}
  tar -cvf ${PACK_DIR}.tar ${PACK_DIR} | tee -a ${MAIN_LOG}
  gzip ${PACK_DIR}.tar | tee -a ${MAIN_LOG}

  if [[ -f ${PACK_DIR}.tar.gz ]]
  then
    echo | tee -a ${MAIN_LOG}
    echo "Logs for ${SERVICE_NAME} cloudera service/s Packed to ${PACK_DIR}.tar.gz file" | tee -a ${MAIN_LOG}
  else
    echo "${PACK_DIR}.tar.gz File Not Found, Please check if directory ${PACK_DIR} created on earlier stage (Create_Pack_Directory/Copy_Log_Directories functions), Exitng.." | tee -a ${MAIN_LOG}
    exit 1
  fi
}

###Main###
Init_Validation
Set_LOG_DIRS ${SERVICE_NAME}
Validate_Log_Directories_Exist ${LOG_DIRS}
Create_Pack_Directory
Copy_Log_Directories
Pack_Logs_Directory
