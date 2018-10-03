#!/bin/bash

## Author: steven.showers@docker.com
## Script to grab latest support.sh and collect output for network troubleshooting.
## Original: https://github.com/docker/libnetwork/blob/1e52a9afbb1c32e7dba297a8113e1fa079607dcc/support/run.sh
# Usage: ./dump-network.sh or bash dump-network.sh

shellcheck(){ ps auxww | grep $$ | grep -wq "bash"; echo $?; }

if [ $(shellcheck) = 1 ]; then
   echo "This script must be executed with BASH."
   echo "Exiting..."
   exit 1
fi

FILE="/tmp/support-sh-$(hostname -s)-$(date +%s%z).txt"

if [[ -z "$(command -v wget)" && -z "$(command -v curl)" ]]; then
   echo -ne "\n'wget' or 'curl' not found\n"
elif [ -z $(command -v wget) ]; then
   curl --connect-timeout 8 -L https://raw.githubusercontent.com/docker/libnetwork/master/support/support.sh -o support.sh.new
else
   wget --timeout=8 -O support.sh.new https://raw.githubusercontent.com/docker/libnetwork/master/support/support.sh
fi

if [[ -z "$(command -v ipvsadm)" ]]; then
   echo -ne "\nThis script is better with ipvsadm. Please install it if you can.\n"
   echo -ne "E.g. yum provides ipvsadm or apt-file search ipvsadm\n"
fi

if [ -s support.sh.new ]; then
   mv support.sh.new support.sh 
   chmod +x support.sh
   if [[ $EUID -ne 0 ]]; then
      echo -ne "\nThis script should be run as root\n"
      echo -ne "\nTrying 'sudo'\n"
      sudo ./support.sh &> ${FILE}
      echo -ne "\nPlease attach this file to the ticket: ${FILE}\n"
   else
      ./support.sh &> ${FILE}
      echo -ne "\nPlease attach this file to the ticket: ${FILE}\n"
   fi
else
   echo -ne "\nUnable to fetch latest support.sh. Using the container version ( a little older )\n"
   docker pull dockereng/network-diagnostic:support.sh
   docker run -v /var/run:/var/run  --network host --privileged dockereng/network-diagnostic:support.sh &> ${FILE}
   echo -ne "\nPlease attach this file to the ticket: ${FILE}\n"
   ## In case there are any errors in the log. E.g. docker couldn't pull image. 
   grep -q -i error ${FILE} && echo -ne "\nErrors occurred while collecting data. Please check and let Support know: cat ${FILE}\n"
fi

if [ -s support.sh ]; then
   echo -ne '\nCleaning up...\n'
   rm -v support.sh
else
   exit 0
fi
