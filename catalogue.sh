#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nodejs -y
VALIDATE $? "NodeJS module disable"


dnf module enable nodejs:20 -y
VALIDATE $? "NodeJS module enable"

dnf install nodejs -y
VALIDATE $? "NodeJS installation"


id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "roboshop user creation"
else
    echo -e "$Y roboshop user already exists $N"
fi
VALIDATE $? "roboshop user creation"


mkdir -p /app
VALIDATE $? "Create application directory"

rm -rf /app/* 
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
VALIDATE $? "Download catalogue code"

cd /app
unzip /tmp/catalogue.zip
VALIDATE $? "Extract catalogue code"
 
npm install
VALIDATE $? "Install catalogue dependencies"


cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue systemd service file"


systemctl daemon-reload
VALIDATE $? "Reload systemd"


systemctl enable catalogue
VALIDATE $? "Enable catalogue service"
systemctl start catalogue
VALIDATE $? "Start catalogue service"


cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongodb repo"


dnf install mongodb-mongosh -y
VALIDATE $? "installing mongodb shell"

STATUS=$(mongosh --host mongodb.tejaswini.site --eval "db.getSiblingDB('catalogue').getCollection('products').find().count()")
if [ $STATUS -lt 0 ]
then
mongosh --host mongodb.tejaswini.site </app/db/master-data.js
VALIDATE $? "Inserting data into catalogue database"
else
echo -e "$Y catalogue database already has data, skipping insertion $N"
fi