#!/bin/bash 

#    Author: steven.showers@docker.com

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

### Functions

# The script should place files in the /tmp directory. 

grab_bundle_prompt(){
    read -p "UCP host (e.g ucp.example.com or IP): " HOST
    read -p "UCP port (default 443, press enter): " PORT
    read -p "UCP user: " USER
    read -sp "UCP pass: " PASS
    # Default to 443 if PORT is empty.
    if [ -z $PORT ]; then
        export PORT=443
    fi
    export AUTHTOKEN=$(curl --insecure -s -X POST -d "{ \"username\":\"$USER\",\"password\":\"$PASS\" }" "https://${HOST}:${PORT}/auth/login" | awk -F ':' '{print $2}' | tr -d '"{}')
    ## echo'ing authtoken as per Carl's original spec
    echo -en "\nAuthtoken: ${AUTHTOKEN}\n"
    curl -k -H "Authorization: Bearer $AUTHTOKEN" https://${HOST}:${PORT}/api/clientbundle -o bundle.zip
    mkdir -p /tmp/${HOST}
    unzip bundle.zip -d /tmp/${HOST}
    exit 0
}

authtoken_check(){
    if [[ -z "$AUTHTOKEN" ]]; then 
        echo "Unable to obtain Authtoken"
        exit 1
    elif [[ "$AUTHTOKEN" == "null" ]]; then 
        echo "Unable to obtain Auth token. Do you have the right URL, USER, and PASSWORD"
        exit 1
    fi
}

jq_check(){
    if [ -z "$(command -v jq)" ]; then
        export jq=no
    fi
}

bin_check(){
    if [ -z "$(command -v curl)" ] || [ -z "$(command -v unzip)" ]; then
        echo -en "\nRequired: curl, unzip\nOptional: jq\n"
        exit 1
    fi
}

grab_authtoken(){
    if ! [ -z $PORT ]; then
        export AUTHTOKEN=$(curl --insecure -s -X POST -d "{ \"username\":\"$USERNAME\",\"password\":\"$PASSWORD\" }" "https://${NODE}:${PORT}/auth/login" | awk -F ':' '{print $2}' | tr -d '"{}')
    else
        export AUTHTOKEN=$(curl --insecure -s -X POST -d "{ \"username\":\"$USERNAME\",\"password\":\"$PASSWORD\" }" "https://${NODE}/auth/login" | awk -F ':' '{print $2}' | tr -d '"{}')
    fi
}

grab_authtoken_jq(){
    if ! [ -z $PORT ]; then
        export AUTHTOKEN=$(curl -sk -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" https://${NODE}:${PORT}/auth/login | jq -r .auth_token)
    else
        export AUTHTOKEN=$(curl -sk -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" https://${NODE}/auth/login | jq -r .auth_token)
    fi
}

download_bundle(){
    if ! [ -z $PORT ]; then
        curl -k -H "Authorization: Bearer $AUTHTOKEN" https://${NODE}:${PORT}/api/clientbundle -o bundle.zip
    else
        curl -k -H "Authorization: Bearer $AUTHTOKEN" https://${NODE}/api/clientbundle -o bundle.zip
    fi
}

extract_bundle(){
    mkdir -p /tmp/${NODE}
    unzip bundle.zip -d /tmp/${NODE}
}

### End Functions

## Accept command line args for username and password per https://github.com/dockersupport/support-tools/pull/83
## Author: steven.showers@docker.com
while getopts ":n:u:p:P:h" opt; do
    export $opt
    case $opt in
        u)
            export USERNAME=$OPTARG
            echo $USERNAME
            ;;
        p)
            export PASSWORD=$OPTARG
            echo $PASSWORD
            ;;
        n)
            export NODE=$OPTARG
            echo $NODE
            ;;

        P)
            export PORT=$OPTARG
            echo $PORT
            ;;
        h)
            echo "
            Syntax: 
            $0 -u USER -p PASS -n NODE

            Example:

            $0 -u admin -p dockeradmin -n ucp.example.com -P 9443

            $0 -u admin -p dockeradmin -n ucp.example.com

            or 

            $0
            "
            exit 0
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            exit 1
            ;;
    esac
done

if [ -z "$1" ]; then
    grab_bundle_prompt
fi 

## Go!

# Confirm available binaries
bin_check
jq_check

# Obtain Auth Bearer token
if [[ $jq = "no" ]]; then
    grab_authtoken
else
    grab_authtoken_jq
fi


## Get the bundle
authtoken_check
download_bundle
extract_bundle
