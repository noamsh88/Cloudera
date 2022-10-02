#!/bin/bash -xv
###########################################################################################################################################
#Script is getting yarn application name and time limit(in minutes) and verify if its application ID is running more time than TIME_LIMIT
#if yes, then script will generate yarn logs of application ID and will kill it
###########################################################################################################################################
#the idea is to have health check script to be added to crontab to avoid long running/zombie yarn applications that running with proceeding
###########################################################################################################################################
export APP_NAME=$1
export TIME_LIMIT=$2
###########################################################################################################################################
export NC='\033[0m'				# No Color
export RED='\033[0;31m'
export YELLOW='\033[0;33m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
###########################################################################################################################################
export DATE=`date +%Y%m%d_%H%M%S`
export MAIN_LOG=$(pwd)/yarn_kill_long_running_apps_${APP_NAME}_${DATE}.log
###########################################################################################################################################

Init_Validation()
{

  if [[ -z ${APP_NAME} || -z ${TIME_LIMIT} ]]
  then
    echo | tee -a ${MAIN_LOG}
    echo "USAGE : `basename $0` <APP_NAME> <TIME_LIMIT in minutes>" | tee -a ${MAIN_LOG}
    echo -e "\nExample: `basename $0` cluster-fm-ingest 80 \n "   | tee -a ${MAIN_LOG}
    echo "APP_NAME - Value should unique application name"    | tee -a ${MAIN_LOG}
    echo "TIME_LIMIT - Limited time in minutes for yarn application name to be executed"  | tee -a ${MAIN_LOG}
    exit 1
  fi

  # Validate Yarn Installed
  which yarn
  if [[ $? -ne 0 ]]
  then
    echo -e ${RED} "Yarn NOT FOUND on $(hostname) , please verify it setup correctly or script is running on correct hostname, exiting..." | tee -a ${MAIN_LOG}
    echo -e ${NC} | tee -a ${MAIN_LOG}
    exit 1
  fi

  # Validate Application name is unique or if application name is currently running
  APP_EXIST_OR_UNIQUE=$(yarn application -list | grep ${APP_NAME} | grep SPARK | wc -l)
  if [[ ${APP_EXIST_OR_UNIQUE} -eq 0 ]]
  then
    echo -e ${RED} "Yarn application Name ${APP_NAME} entered NOT FOUND , please verify correct app name to be entered, exiting..." | tee -a ${MAIN_LOG}
    echo -e ${NC} | tee -a ${MAIN_LOG}
    exit 1
  elif [[ ${APP_EXIST_OR_UNIQUE} -gt 1 ]]
  then
    echo -e ${RED} "The are 2 or more Yarn applications Name related to argument entered for APP_NAME variable ( ${APP_NAME} ) , please enter UNIQUE application name, exiting..." | tee -a ${MAIN_LOG}
    echo -e ${NC} | tee -a ${MAIN_LOG}
    exit 1
  fi

}

Generate_Yarn_Application_Logs()
{
  # Creates log directory
  export YARN_LOG_DIR=$(pwd)/yarn_logs_${APP_NAME}_${YARN_APP_ID}_${DATE}
  mkdir -p ${YARN_LOG_DIR}

  # Export APP ID Logs
  echo -e ${CYAN} "yarn logs -applicationId ${YARN_APP_ID} > ${YARN_LOG_DIR}/yarn_${YARN_APP_ID}.log" | tee -a ${MAIN_LOG}
  yarn logs -applicationId ${YARN_APP_ID} > ${YARN_LOG_DIR}/yarn_${APP_NAME}_${YARN_APP_ID}.log

  #Pack log direcotry
  export LOG_DIR_NAME=$(basename ${YARN_LOG_DIR})
  tar -cvf ${LOG_DIR_NAME}.tar ${LOG_DIR_NAME}
  gzip ${LOG_DIR_NAME}.tar

  echo -e ${GREEN} "Yarn Application ID ${YARN_APP_ID} logs exported and packed to following file path:" | tee -a ${MAIN_LOG}
  echo "${YARN_LOG_DIR}.tar.gz" | tee -a ${MAIN_LOG}
  echo -e ${NC}

}


Kill_Yarn_App_If_Running_too_Long()
{
  # Get Yarn Application ID
  export YARN_APP_ID=$(yarn application -list | grep ${APP_NAME} | grep SPARK | awk '{print $1}')

  # Get Yarn Application Start Time
  export APP_START_TIME=$(yarn application -status ${YARN_APP_ID} | grep Start-Time | awk '{print $3}')

  # Caluclate elapsed time of running application in minutes
  export YARN_APP_ID_START_TIME=$( date -d @$(  echo "(${APP_START_TIME}+ 500) / 1000" | bc) +%s )
  export CUR_TIME=$(date +%s)
  export YARN_APP_ID_ELAPSED_TIME=$((${CUR_TIME}-${YARN_APP_ID_START_TIME}))
  export YARN_APP_ID_ELAPSED_TIME=$(( ${YARN_APP_ID_ELAPSED_TIME} / 60))
  echo -e ${CYAN} "Application ID ${YARN_APP_ID} is currently running for ${YARN_APP_ID_ELAPSED_TIME} minutes"  | tee -a ${MAIN_LOG}
  echo -e ${NC}  | tee -a ${MAIN_LOG}

  # Verify if its application ID is running more time than TIME_LIMIT, if yes, then script will generate yarn logs of application ID and will kill it
  if [[ ${YARN_APP_ID_ELAPSED_TIME} -gt ${TIME_LIMIT} ]]
  then
    echo -e ${YELLOW} "Yarn Application ID ${YARN_APP_ID} is running for ${YARN_APP_ID_ELAPSED_TIME} minutes, which is more than what requuired ( ${TIME_LIMIT} minutes)"   | tee -a ${MAIN_LOG}
    echo -e ${NC}   | tee -a ${MAIN_LOG}

    echo -e ${CYAN} "Killing ${YARN_APP_ID} Application ID..." | tee -a ${MAIN_LOG}
    echo -e ${NC} | tee -a ${MAIN_LOG}
    yarn application -kill ${YARN_APP_ID}
    echo -e ${GREEN} "Yarn Application ID ${YARN_APP_ID} Killed " | tee -a ${MAIN_LOG}

    echo -e ${CYAN} "Generating Yarn ${YARN_APP_ID} logs..." | tee -a ${MAIN_LOG}
    echo -e ${NC} | tee -a ${MAIN_LOG}
    Generate_Yarn_Application_Logs
  else
    echo -e ${GREEN} "Yarn Application ID ${YARN_APP_ID} is running as expected (Less than ${TIME_LIMIT} minutes)" | tee -a ${MAIN_LOG}
    echo -e ${NC} | tee -a ${MAIN_LOG}
  fi

}


###Main###
Init_Validation
set -eu
Kill_Yarn_App_If_Running_too_Long
