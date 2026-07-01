#!/bin/bash

LOGS_DIR="/var/log/roboshop"
sudo mkdir -p $LOGS_DIR
sudo chown -R ec2-user:ec2-user $LOGS_DIR
sudo chmod -R 755 $LOGS_DIR

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $USER_ID -ne 0 ];then
    echo -e "$Timestamp [ERROR] $R Please switch to root before executing $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$Timestamp [ERROR] Failure....! $R " | tee -a $LOGS_FILE
    else
        echo -e "$Timestamp [Info] Success..! $G" | tee -a $LOGS_FILE
    fi
}


dnf module disable redis -y &>> $LOGS_FILE
dnf module enable redis:7 -y &>> $LOGS_FILE
dnf install redis -y &>> $LOGS_FILE
VALIDATE $? "Installing Redis:7"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connections"


systemctl enable redis &>> $LOGS_FILE
systemctl start redis &>> $LOGS_FILE
VALIDATE $? "Starting redis"



