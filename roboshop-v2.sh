#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z07423591GD2G8GTI4KPQ"
DOMAIN_NAME="daws-90.online"

#########Validation##########
if [ $# -lt 2 ]; then
    echo "atleast 2 aruguemts need to be passed"
    exit 1
fi 

ACTION_ITEM=$1
echo "$ACTION_ITEM"
shift 
echo $@
    