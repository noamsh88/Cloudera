#!/bin/ksh
set -exv
###########################################################################################################################
#Script Actions:
#1. Get the Cloudera Version and license Expiration Date for each host via API
#2. Calculate the days left for the license
#3. Send output via mail
#Assumptions:
#cm_client python package is installed on execution server
###########################################################################################################################
export DATE=`date +%Y%m%d_%H%M%S`
export SCRIPT_DIR=`pwd`
export LOG_DIR=${SCRIPT_DIR}/logs
mkdir -p ${SCRIPT_DIR}/logs
export LOG_FILE=${SCRIPT_DIR}/logs/Cloudera_Envs_Expiration_Dates_${DATE}.log
###########################################################################################################################

Pre_Validations()
{
  if [[ -z ${SCRIPT_DIR} ]]
  then
    echo
    echo "Please Set value for SCRIPT_DIR variable "
    exit 1
  fi

  # Validate if Cloudera_Envs_Hosts_List.lst path is correct
  if [[ ! -e ${SCRIPT_DIR}/cloudera-envs-hosts-list.lst ]]
  then
    echo "Hosts list file not found under ${SCRIPT_DIR} directory , Please set its correct path on CDH_HOSTS_FILE variable"
    exit 1
  fi

  # Validate if ${SCRIPT_DIR}/get-cloudera-license-expiration-date.py exists
  if [[ ! -e ${SCRIPT_DIR}/get-cloudera-license-expiration-date.py ]]
  then
    echo "${SCRIPT_DIR}/get-cloudera-license-expiration-date.py API Script Not Found , Please Copy It Under ${SCRIPT_DIR} directory"
    exit 1
  fi

  # Validate if Cloudera API python package (cm-client) installed
  PKG_INSTALLED=`pip list | grep -F cm-client | wc -l`
  if [ ${PKG_INSTALLED} -ne 1 ]
  then
    echo "cm-client Python Package is not installed on server"
    echo "pip install cm-client"
    exit 1
  fi

  # Validate if ${SCRIPT_DIR}/SendHtmlMail exists
  if [[ ! -e ${SCRIPT_DIR}/SendHtmlMail ]]
  then
    echo "${SCRIPT_DIR}/SendHtmlMail Script Not Found , Please Copy It Under ${SCRIPT_DIR} directory"
    exit 1
  fi

}


Get_License_Expiration_Date()
{

  # Execute API on V7 Cloudera Hosts
  for cdh_host in $(cat ${SCRIPT_DIR}/cloudera-envs-hosts-list.lst); do
    python ${SCRIPT_DIR}/get-cloudera-license-expiration-date.py ${cdh_host} v41 | tee -a ${LOG_FILE}
  done

}

Generate_HTML_File()
{
  cd ${SCRIPT_DIR}
  python create-html-table.py ${LOG_FILE}

  if [ ! -e ${SCRIPT_DIR}/html-table.html ]
  then
    echo "${SCRIPT_DIR}/html-table.html file didn't created"
    echo "please check execution of :     ${SCRIPT_DIR}/create-html-table.py ${LOG_FILE}"
  fi

}

Send_Mail()
{
  FROM=devops\@company.com
  TO=devops\@company.com
  ${SCRIPT_DIR}/SendHtmlMail -to ${TO} -from ${FROM}  -subject "Cloudera Envs License Expiration Dates" -htmlfile ${SCRIPT_DIR}/html-table.html

  # Delete temp html table file on server
  rm -fr ${SCRIPT_DIR}/html-table.html

}

###Main###
Pre_Validations
Get_License_Expiration_Date
Generate_HTML_File
Send_Mail
