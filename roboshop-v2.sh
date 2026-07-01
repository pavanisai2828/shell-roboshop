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
shift
if [ "$ACTION_ITEM" != "create" ] && [ "$ACTION_ITEM" != "delete" ]; then
    echo "first argument should be either create or destroy"
    exit 1
else

get_instance_id(){
    instance_name=$1
    aws ec2 describe-instances --filters "Name=tag:Name,Values=roboshop-$instance_name" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text
}

for instance in $@
do
    echo "checking for instance id"
    INSTANCE_ID=$(get_instance_id $instance)
    if [ $ACTION_ITEM == "create" ]; then
        if [ $INSTANCE_ID == "None" ]; then
            echo "Launching instance : $instance"
            INSTANCE_ID=$(aws ec2 run-instances \
                --image-id $AMI_ID \
                --instance-type t3.micro \
                --security-groups "roboshop-common" "roboshop-$instance" \
                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
                --query 'Instances[0].InstanceId' \
                --output text)
            echo "instance created with id: $INSTANCE_ID"
        
            ###############Route 53####################
            if [ $instance == "frontend" ];then
                IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                    --query 'Reservations[*].Instances[*].PublicIpAddress' \
                    --output text
                )
            R53_RECORD="$DOMAIN_NAME"
            else
                IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
                    --output text
                )
            R53_RECORD=$instance.$DOMAIN_NAME
            fi
            aws route53 change-resource-record-sets \
            --hosted-zone-id $ZONE_ID \
            --change-batch '
                {   
                    "Comment": "Update A record to new IP",
                    "Changes": [
                        {
                            "Action": "UPSERT",
                            "ResourceRecordSet": {
                                "Name": "'$R53_RECORD'",
                                "Type": "A",
                                "TTL": 1,
                                "ResourceRecords": [
                                    {
                                        "Value": "'$IP'"
                                    }
                                ]
                            }
                        }
                    ]
                }
            '
            echo "updated R53 record for: $instance"
        else
            echo  "instance already running  with instance id : $INSTANCE_ID"
            if [ $instance == "frontend" ];then
                IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                    --query 'Reservations[*].Instances[*].PublicIpAddress' \
                    --output text
                )
            R53_RECORD="$DOMAIN_NAME"
            else
                IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
                    --output text
                )
            R53_RECORD=$instance.$DOMAIN_NAME
            fi
            aws route53 change-resource-record-sets \
                --hosted-zone-id $ZONE_ID \
                --change-batch '
                    {   
                        "Comment": "Update A record to new IP",
                        "Changes": [
                            {
                                "Action": "UPSERT",
                                "ResourceRecordSet": {
                                    "Name": "'$R53_RECORD'",
                                    "Type": "A",
                                    "TTL": 1,
                                    "ResourceRecords": [
                                        {
                                            "Value": "'$IP'"
                                        }
                                    ]
                                }
                            }
                        ]
                    }
                '
                echo "updated R53 record for: $instance"
        fi

    else
        if [ $INSTANCE_ID == "None" ];
            echo "$instance already destroyed, nothing to do..."
        else
            aws ec2 terminate-instances --instance-ids $INSTANCE_ID
            echo "Terminating Instance: $instance"
        fi
    fi

done
    