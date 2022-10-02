#!/bin/bash
##############################################################################################################
#Script is restarting cloudera agent service (cloudera-scm-agent.service)
#############################################################################################################
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m'
#############################################################################################################

Init_Validation()
{
  #Validate Cloudera Service/s exist
  export CNT_SERVICES=`sudo systemctl list-units --type=service -all | grep cloudera-scm-agent.service | awk '{print $1}' | wc -l`
  if [[ ${CNT_SERVICES} -eq 0 ]]
  then
    echo -e ${RED} "cloudera-scm-agent.service not found , please check  Cloudera setup properly on `hostname` host, exiting.."
    echo -e ${NC}
    exit 1
  fi

}

Validate_Success_Operation()
{
  EXIT_STATUS=$?

  if [[ $EXIT_STATUS -ne 0 ]]
   then
    LAST_CLI=`echo history |tail -n2 |head -n1 | awk '{print $2}'`
    echo "Failed to Execute Followng CLI:"
    echo -e ${RED} "${LAST_CLI}"
    echo -e "Exiting.."
    echo -e ${NC}
    exit 1
  fi

}

Validate_Cloudera_Agent_Service_Is_Up()
{
  #Validate if Cloudera agent is up
  #IsUP parameter value: 0=down , 1=up
  unset IsUP
  IsUP=`sudo systemctl status cloudera-scm-agent.service | grep active | wc -l`

  if [[ ${IsUP} -eq 1 ]]
  then
    sudo systemctl status cloudera-scm-agent.service
    echo -e ${GREEN} "#####################################################"
    echo " cloudera-scm-agent.service Service Restarted Successfully"
    echo " #####################################################"
    echo -e ${NC}
    exit 0
  else
    echo -e ${RED} "#################################################################################################"
    echo "Cloudera Service cloudera-scm-agent.service is not started properly, please try to execute following CLI and check for errors: "
    echo "sudo systemctl restart cloudera-scm-agent.service "
    echo "#################################################################################################"
    echo -e ${NC}
    exit 1
  fi

}

Restart_Cloudera_Agent_Service()
{
    echo "Re-Starting Service cloudera-scm-agent.service:"
    sudo systemctl restart cloudera-scm-agent.service

    Validate_Success_Operation

    sleep 10

    Validate_Cloudera_Agent_Service_Is_Up

}

###Main###
Init_Validation
Restart_Cloudera_Agent_Service
