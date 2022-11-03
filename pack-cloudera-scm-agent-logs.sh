#!/bin/bash
set -eux
##############################################################
#Script is packing Cloudera agent logs from all cluster Nodes#
##############################################################
export DATE=`date +%Y%m%d_%H%M%S`
export AGENT_LOG_DIR=/var/log/cloudera-scm-agent
export AGENT_LOG_DIRNAME=$(basename ${AGENT_LOG_DIR})
export NN1_HOST_NAME=$(hostname -i)
#export TRG_DIR=$(pwd)
export TRG_DIR=/home/pmc
export SCRIPT_DIR=$(pwd)
##############################################################
NC='\033[0m'				# No Color
GREEN='\033[0;32m'	# Green
##############################################################

# tar and Copy NN1 cloudera-scm-agents logs directory
sudo rm -fr ${TRG_DIR}/cloudera-scm-agent ${TRG_DIR}/${AGENT_LOG_DIRNAME}-$(hostname).tar; sudo scp -r ${AGENT_LOG_DIR} ${TRG_DIR} ; cd ${TRG_DIR} ; sudo tar -cvf ${AGENT_LOG_DIRNAME}-$(hostname).tar ${AGENT_LOG_DIRNAME}; sudo chown ${USER}:${USER} ${TRG_DIR}/${AGENT_LOG_DIRNAME}-$(hostname).tar;

# tar and Copy of rest of cluster cloudera-scm-agents logs directory
for HOST_NAME in $(cat /etc/hosts | grep -v $(hostname -i) | awk '{print $2}')
do
  ssh ${USER}@${HOST_NAME} "sudo rm -fr ${TRG_DIR}/cloudera-scm-agent ${TRG_DIR}/${AGENT_LOG_DIRNAME}-${HOST_NAME}.tar; sudo scp -r ${AGENT_LOG_DIR} ${TRG_DIR} ; cd ${TRG_DIR} ; sudo tar -cvf ${AGENT_LOG_DIRNAME}-${HOST_NAME}.tar ${AGENT_LOG_DIRNAME}; sudo chown ${USER}:${USER} ${TRG_DIR}/${AGENT_LOG_DIRNAME}-${HOST_NAME}.tar;"
  scp ${USER}@${HOST_NAME}:${TRG_DIR}/${AGENT_LOG_DIRNAME}-${HOST_NAME}.tar  ${TRG_DIR}
done

# move all packed logs dirs into 1
cd ${TRG_DIR}
mkdir ${TRG_DIR}/cloudera-scm-agent-${DATE}
mv ${TRG_DIR}/${AGENT_LOG_DIRNAME}*.tar ${TRG_DIR}/cloudera-scm-agent-${DATE}


# pack output direcory
cd ${TRG_DIR}
tar -cvf cloudera-scm-agent-${DATE}.tar cloudera-scm-agent-${DATE}
gzip cloudera-scm-agent-${DATE}.tar

echo -e ${GREEN} "DONE - cloudera-scm-agents from all cluster nodes packed to ${TRG_DIR}/cloudera-scm-agent-${DATE}.tar.gz file"
echo -e ${NC}
