#!bin/bash
LOGS_DIR="/var/log/roboshop"
sudo mkdir -p $LOGS_DIR
sudo chown -R ec2-user:ec2-user $LOGS_DIR
sudo chmod -R 755 $LOGS_DIR
LOGS_FILE="$LOGS_DIR/$0.log"


USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
Timestamp=$(date "+%Y-%m-%d %H:%M:%S")

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

dnf install mysql-server -y &>> $LOGS_FILE
VALIDATE $? "installing mysql"

systemctl enable mysqld &>> $LOGS_FILE
systemctl start mysqld &>> $LOGS_FILE
VALIDATE $? "Start MySQL Service"

mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "change the default root password in order to start using the database service"