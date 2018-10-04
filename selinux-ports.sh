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


## A simple script for testing SELinux labels on ports on managers and workers.
## See: https://docs.docker.com/ee/ucp/admin/install/system-requirements/#ports-used
## The result is a log file in `/tmp`.

shellcheck(){ ps auxww | grep $$ | grep -wq "bash"; echo $?; }

if [ $(shellcheck) = 1 ]; then
   echo "This script must be executed with BASH."
   echo "Exiting..."
   exit 1
fi

HOST=$(hostname -s)
TYPE=$(echo $1 | tr '[:upper:]' '[:lower:]')
NC=$(which seinfo 2> /dev/null 1> /dev/null; echo $?)
FILE=/tmp/se-ports-from-$(hostname -s)-SECONTEXTS-$(date +%s%z).log

MANAGER_PORTS='
179
2376
2377
6443
6444
7946
9099
10250
12376
12378
12379
12380
12381
12382
12383
12384
12385
12386
12387'

WORKER_PORTS='
179
12376
6444
7946
9099
10250
12376
12378'


if [ "$NC" = "1" ]; then
   echo "You must install setools-console: e.g. yum install setools-console -y"
   exit 1
elif [ -z "$TYPE" ]; then
   echo "Syntax: selinux-ports.sh <worker-OR-manager>"
   exit 1
fi
if [ "$TYPE" = "manager" ]; then
   echo -ne "\n${HOST} is a ${TYPE}\n" | tee -a ${FILE}
   sleep 2
   for i in $MANAGER_PORTS; do echo -ne "\n***TESTING $(hostname -s) SECONTEXTS on port $i***\n"; seinfo --portcon=${i};  done 2>&1 | tee -a ${FILE}
elif [ "$TYPE" = "worker" ]; then
   echo -ne "\n${HOST} is a ${TYPE}\n" | tee -a ${FILE}
   sleep 2
   for i in $WORKER_PORTS; do echo -ne "\n***TESTING $(hostname -s) SECONTEXTS on port $i***\n"; seinfo --portcon=${i};  done 2>&1 | tee -a ${FILE}
fi

echo -en "\nPlease attach this file to the case: ${FILE}\n"
