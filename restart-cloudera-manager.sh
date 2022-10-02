#!/bin/bash -xv
##################################################################################
# Script checking for cloudera manager services installed on host and restart them
##################################################################################
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m'
#############################################################################################################

Init_Validation()
{
  #Validate Cloudera Service/s exist
  export CNT_SERVICES=`sudo systemctl list-units --type=service -all | grep cloudera | awk '{print $1}' | wc -l`
  if [[ ${CNT_SERVICES} -eq 0 ]]
  then
    echo -e ${RED} "Cloudera Services not found , please check if Cloudera installed fine on `hostname` host, exiting.."
    echo -e ${NC}
    exit 1
  fi

}

Validate_Success_Operation()
{
  EXIT_STATUS=$?

  if [[ $EXIT_STATUS -ne 0 ]]
   then
    LAST_CLI=`echo `history |tail -n2 |head -n1` | sed 's/[0-9]* //'`
    echo "Failed to Execute Followng CLI:"
    echo -e ${RED} "${LAST_CLI}"
    echo -e "Exiting.."
    exit 1
  fi

}

Validate_Cloudera_Service_Is_Up()
{
  #Validate if postgres service is up
  #IsUP parameter value: 0=pg is down , 1=pg is up
  unset IsUP
  IsUP=`sudo service ${SERVICE} status | grep active | wc -l`

  if [[ ${IsUP} -eq 1 ]]
  then
    sudo service ${SERVICE} status
    echo -e ${GREEN} "#########################################"
    echo " ${SERVICE} Service Restarted Successfully"
    echo " #########################################"
    echo -e ${NC}
  else
    echo -e ${RED} "#################################################################################################"
    echo "Cloudera Service ${SERVICE} is not started properly, please try to execute following CLI and check for errors: "
    echo "sudo service ${SERVICE} restart "
    echo "#################################################################################################"
    echo -e ${NC}
    exit 1
  fi

}

Restart_Cloudera_Services()
{
  for SERVICE in $( sudo systemctl list-units --type=service -all | grep cloudera | awk '{print $1}' );do

    #Validate service name contain cloudera string
    if [[ ! `echo ${SERVICE} | grep cloudera` ]]; then
      echo -e ${RED} "${SERVICE} name is not contain *cloudera*, please check cloudera setup is as expected or that service is availble, try execute: \"journalctl -xe\" for more info "
      echo -e ${NC}
      exit 1
    fi

    echo "Re-Starting Service ${SERVICE}:"
    sudo service ${SERVICE} stop
    Validate_Success_Operation

    sudo service ${SERVICE} start

    Validate_Success_Operation

    sleep 10

    Validate_Cloudera_Service_Is_Up

  done

}

###Main###
Init_Validation
Restart_Cloudera_Services
