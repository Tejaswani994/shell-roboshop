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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Copying rabbitmq repo file"


dnf install rabbitmq-server -y
VALIDATE $? "Installing rabbitmq server"

systemctl enable rabbitmq-server
systemctl start rabbitmq-server
VALIDATE $? "Starting rabbitmq server"


rabbitmqctl add_user roboshop roboshop123
VALIDATE $? "Adding roboshop user"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Setting permissions to roboshop user"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
echo "Script execution completed at: $(date)" | tee -a $LOG_FILE
echo "Total execution time: $TOTAL_TIME seconds" | tee -a $LOG_FILE