#!/bin/bash
START_TIME=$(date +%s)
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
dnf install python3 gcc python3-devel -y
VALIDATE $? "Installing python3 and dependencies"

id roboshop
if [ $? -ne 0 ]
then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "Creating roboshop user"
else
    echo -e "$Y roboshop user already exists $N"
fi 

mkdir -p /app
VALIDATE $? "Creating application directory"

rm -rf /app/*
curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip
VALIDATE $? "Downloading payment code"
cd /app
unzip /tmp/payment.zip
VALIDATE $? "Extracting payment code"

cd /app
pip3 install -r requirements.txt
VALIDATE $? "Installing payment dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Copying payment systemd service file"

systemctl daemon-reload
VALIDATE $? "Reloading systemd daemon"
systemctl enable payment
VALIDATE $? "Enabling payment service to start on boot"

systemctl start payment
VALIDATE $? "Starting payment service"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
echo "Script execution completed at: $(date)" | tee -a $LOG_FILE
echo "Total execution time: $TOTAL_TIME seconds" | tee -a $LOG_FILE







