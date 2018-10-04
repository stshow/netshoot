#!/bin/bash

#    Author: steven.showers@docker.com
#    Copyright (C) Steven Showers 2018

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

## A simple script to test upstream URLs in DTR nginx load balancer. Useful for testing `dtr-ol` connectivity.
## Usage: ./dtr-ol-ping.sh or bash dtr-ol-ping.sh

shellcheck(){ ps auxww | grep $$ | grep -wq "bash"; echo $?; }

if [ $(shellcheck) = 1 ]; then
   echo "This script must be executed with BASH."
   echo "Exiting..."
   exit 1
fi

FILE=/tmp/dtr-ol-ping-$(hostname -s)-$(date +%s%z).txt

if [ -z $(docker ps -a -f name=dtr-nginx -q) ]; then
   echo -ne '\nWARNING: You do not appear to be running the script on a DTR node.\n'
   echo -ne '\nPlease copy this script to a DTR node and execute it there\n\n'
   exit 1
fi

ping-test(){
   for i in `grep -A1 -i upstream /tmp/nginx.conf | grep server | awk '{print $2}' | tr -d ";" | sed 's/\:.*//g'`; do 
     docker run --rm -it --net dtr-ol --name dtrol-test1 alpine ping -c 2 $i; done 2>&1 > ${FILE}
}

if [ -f /tmp/nginx.conf ]; then
   echo -en '\nTesting dtr-ol...\n'
   rm /tmp/nginx.conf
   docker cp $(docker ps -a -f name=dtr-nginx -q):/config/nginx.conf /tmp 
   ping-test
   echo -en '\nCleaning up...\n'
   rm -v /tmp/nginx.conf
   echo "Please upload this file to the ticket: ${FILE}"
   exit 0
else
   docker cp $(docker ps -a -f name=dtr-nginx -q):/config/nginx.conf /tmp 
   echo -en '\nTesting dtr-ol...\n'
   ping-test
   echo -en '\nCleaning up...\n'
   rm -v /tmp/nginx.conf
   echo "Please upload this file to the ticket: ${FILE}"
   exit 0
fi
