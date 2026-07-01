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
        echo -e "$Timestamp $2 [ERROR] Failure....! $R " | tee -a $LOGS_FILE
    else
        echo -e "$Timestamp $2 [Info] Success..! $G" | tee -a $LOGS_FILE
    fi
}

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding rabbitmq repo"

dnf install rabbitmq-server -y &>> $LOGS_FILE
VALIDATE $? "installing rabbitmq" &>> $LOGS_FILE

systemctl enable rabbitmq-server &>> $LOGS_FILE
systemctl start rabbitmq-server &>> $LOGS_FILE
VALIDATE $? "Start rabbitmq Service"

rabbitmqctl add_user roboshop roboshop12 &>> $LOGS_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOGS_FILE
VALIDATE $? "create one user for the application"