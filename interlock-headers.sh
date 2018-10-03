#!/bin/bash

# Author: steven.showers@docker.com
# Purpose: Quickly check HTTP GET requests for Host headers and more. 
# Usage: ./interlock-headers.sh help
## HTTPS offsets work well with TLSv1.2 and likely 1.1. 

shellcheck(){ ps auxww | grep $$ | grep -wq "bash"; echo $?; }

if [ $(shellcheck) = 1 ]; then
   echo "This script must be executed with BASH."
   echo "Exiting..."
   exit 1
fi

TASK=$(docker ps -qf name=ucp-interlock-proxy)
FILE=/tmp/interlock-headers-$(hostname -s)-$(date +%s%z).txt
TYPE=$(echo $1 | tr '[:upper:]' '[:lower:]')

kill () {
printf "\nExiting...\n"
exit 1
}

trap kill INT

options(){
   echo -en '\n'
   echo "Syntax: ./interlock-headers.sh <OPTIONS>

Options:

  http          Capture HTTP Headers.
  https         Capture common name from TLS ClientHello. This is Server Name Indication (SNI).
  all           Captures all packets in a pcap file. Helpful if offsets obscure server name in SNI.
  help          Displays detailed usage instructions."
   echo -en '\n\n'
}

helpfunc(){
   echo "HOW TO USE THIS SCRIPT:

Before you begin:

1.) Enable a UCP client bundle: https://docs.docker.com/ee/ucp/user-access/cli/
2.) docker ps -a -f status=running -f name=ucp-interlock-proxy
3.) Take note of the nodes that the 'ucp-interlock-proxy' service tasks are running on:

Name Syntax: <UCP-NODE>/<SERVICE-TASK-NAME>

4.) Copy this file to each of the UCP nodes with 'ucp-interlock-proxy' tasks and then SSH in.
There should be at least two service tasks with published ports in the above 'docker ps' output.

Script usage

If the file is executable:

./interlock-headers.sh <OPTIONS>

If it is not executable:

bash interlock-headers.sh <OPTIONS>

Options:

  http          Capture HTTP Headers.
  https         Capture common name from TLS ClientHello. This is Server Name Indication (SNI).
  all           Captures all packets in a pcap file. Helpful if offsets obscure server name in SNI.
  help          Displays detailed usage instructions.


"
}


if [ -z $TASK ]; then
   echo -en '\n'
   echo "ERROR: Didn't find any ucp-interlock-proxy containers!"
   echo -en '\n'
   echo "Is this the correct node?"
   echo "Try running: docker ps -a | grep -i ucp-interlock-proxy "
   echo -en '\n'
   options
   exit 1
elif [ -z $TYPE ]; then
   echo -ne "\nUse 'help' if you need detailed usage instructions.\n\n"
   options
   exit 1
elif ! [ -z $TASK ] && [ $1 == 'https' ]; then
   echo -ne "\nDumping SNI (HTTPS)...\n"
   echo "Press CTRL + C after you've seen a few packets!"
   sleep 2
   docker run -it --rm --net container:${TASK} --privileged=true nicolaka/netshoot tcpdump -i any -s 0 -A '(tcp[((tcp[12:1] & 0xf0) >> 2)+5:1] = 0x01) and (tcp[((tcp[12:1] & 0xf0) >> 2):1] = 0x16)' | tee -a ${FILE}
   echo "------------------------------"
   echo -en '\n'
   echo "Attach file to ticket: ${FILE}"
   echo -en '\n'
elif ! [ -z $TASK ] && [ $1 == 'http' ]; then
   echo "Press CTRL + C after you've seen a few packets!"
   sleep 2
   docker run -it --rm --net container:${TASK} --privileged=true nicolaka/netshoot tcpdump -i any -s 0 -A 'tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420' | tee -a ${FILE}
   echo "------------------------------"
   echo -en '\n'
   echo "Attach file to ticket: ${FILE}"
   echo -en '\n'
elif ! [ -z $TASK ] && [ $1 == 'help' ]; then
   helpfunc
elif ! [ -z $TASK ] && [ $1 == 'all' ]; then
   echo -ne "\nNote: You will not see packets displayed on the screen. Please confirm that 'packets received by filter' is not '0' after you press CTRL+C\n\n"
   read -p "Please enter your configured Layer 7 routing port, if unknown leave blank: " PORT
   if ! [ -z $PORT ]; then
      echo -ne "\nRecreate the issue and then press CTRL + C when you are finished.\nNo packets will be shown during capture.\n\n"
      PCAP=capture-interlock-port-${PORT}-$(date +%s).pcap
      docker run -it --rm --net container:${TASK} --privileged=true -v ${PCAP}:/PCAP nicolaka/netshoot tcpdump -i any -s0 port ${PORT} -w ${PCAP}
      MOUNT=$(docker volume inspect ${PCAP} --format '{{.Mountpoint}}')
      ### Need to inspect volume and grab data from it
      echo "------------------------------"
      echo -en '\n'
      echo "Attach file to ticket: ${MOUNT}/${PCAP}"
      echo -en '\nYou will need to be user "root" to access this file.\n\n'
      echo -en '\n'
   elif [ -z $PORT ]; then
        echo -en "\nYou didn't enter a port.\n(The file could become large quickly)\n\n"
	    read -p "Are you sure you want to proceed? (yes/no): " ANSWER
	    ANSWER=$(echo $ANSWER | tr '[:upper:]' '[:lower:]')
	    if [ "$ANSWER" == "no" ]; then
	       echo -en '\nExiting...\n'
	       exit 0
	    elif [ "$ANSWER" == "yes" ]; then
            echo -ne "\nRecreate the issue and then press CTRL + C when you are finished.\nNo packets will be shown during capture.\n\n"
            PCAP=capture-interlock-port-${PORT}-$(date +%s).pcap
            docker run -it --rm --net container:${TASK} --privileged=true -v ${PCAP}:/PCAP nicolaka/netshoot tcpdump -i any -s0 -w ${PCAP}
            MOUNT=$(docker volume inspect ${PCAP} --format '{{.Mountpoint}}')
            echo "------------------------------"
            echo -en '\n'
            echo "Attach file to ticket: ${MOUNT}/${PCAP}"
            echo -en '\nYou will need to be user "root" to access this file.\n\n'
            echo -en '\n'
        else
        	echo -en '\nPlease answer yes or no.\n'
        	echo -en '\nExiting...\n'
        	exit 1
        fi
   fi 
fi

