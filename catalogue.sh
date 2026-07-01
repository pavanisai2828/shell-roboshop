#!bin/bash
LOGS_DIR="/var/log/roboshop"
sudo mkdir -p $LOGS_DIR
sudo chown -R ec2-user:ec2-user $LOGS_DIR
sudo chmod -R 755 $LOGS_DIR
LOGS_FILE="$LOGS_DIR/$0.log"
SCRIPT_DIR="$PWD"

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

dnf module disable nodejs -y
VALIDATE $? "Disable current module"
dnf module enable nodejs:20 -y
VALIDATE $? "Enable required module"

dnf install nodejs -y &>> $LOGS_FILE
VALIDATE $? "Install NodeJS" &>> $LOGS_FILE

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

rm -rf /app
VALIDATE $? "Removing existing code"

rm -rf /tmp/catalogue.zip
VALIDATE $? "Removed catalogue zip"

mkdir -p /app  &>>$LOGS_FILE
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
cd /app 
unzip /tmp/catalogue.zip
VALIDATE $? "Download the application code and extract"

npm install 
VALIDATE $? "installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
VALIDATE $? "Load the service."



cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-mongosh -y
VALIDATE $? "Installing MongoDB"

INDEX=$(mongosh --host mongodb.daws-90.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')


if [ $INDEX -lt 0 ]; then
    mongosh --host mongodb.daws-90.online </app/db/master-data.js &>>$LOGS_FILE
    VALIDATE $? "Load Products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl enable catalogue &>> $LOGS_FILE
systemctl start catalogue &>> $LOGS_FILE
