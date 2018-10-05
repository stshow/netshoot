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

AWS_AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
LOCAL_IP=$(curl -sL http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl -sL http://169.254.169.254/latest/meta-data/public-ipv4)
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq '.instanceType')
ARCH=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq '.architecture')

echo "
Instance Info: 

Region: $AWS_AZ
Instance Type: $INSTANCE_TYPE
Architecture: $ARCH
Local IP: $LOCAL_IP
Public IP: $PUBLIC_IP
"
