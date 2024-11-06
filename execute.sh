#!/bin/bash

#******************************************************************************
# * @file           : execute.sh
# * @brief          : 
# ******************************************************************************
# * @attention
# *
# * <h2><center>&copy; Copyright (c) 2022 STMicroelectronics.
# * All rights reserved.</center></h2>
# *
# * This software component is licensed by ST under BSD 3-Clause license,
# * the "License"; You may not use this file except in compliance with the
# * License. You may obtain a copy of the License at:
# *                        opensource.org/licenses/BSD-3-Clause
# ******************************************************************************

# Define the YAML file
TEMPLATE_FILE="template.yaml"
REMOTE_SCRIPT_PATH="~/"

# Function to display help
usage() {
    echo "Usage: $0 -i REMOTE_IP_ADDRESS"
    exit 1
}

# Function to copy file to the board
copy_file_to_board() {
    local FILE_TO_COPY="$1"
    REMOTE_FILE_PATH=${REMOTE_SCRIPT_PATH}${FILE_TO_COPY}
    scp $FILE_TO_COPY root@$REMOTE_IP_ADDRESS:$REMOTE_FILE_PATH    
    # Update the line ending
    ssh root@$REMOTE_IP_ADDRESS "sed -i.bak 's/\r$//' $REMOTE_FILE_PATH"

    if [ $? -ne 0 ]; then
        echo "Failed to copy $FILE_TO_COPY file to the board."
        exit 1
    fi

    #Delete the backup file
    ssh root@$REMOTE_IP_ADDRESS "rm $REMOTE_FILE_PATH.bak"
}


# Parse command line arguments
while getopts ":i:" opt; do
    case ${opt} in
        i )
            REMOTE_IP_ADDRESS=$OPTARG
            ;;
        \? )
            usage
            ;;
    esac
done

# Check that the IP address argument is provided
if [ -z "$REMOTE_IP_ADDRESS" ]; then
    usage
fi

copy_file_to_board "setup.sh"
copy_file_to_board "config.json"
copy_file_to_board "uninstall.sh"

# Copy certs to the remote server
scp -r ./claim-certs root@$REMOTE_IP_ADDRESS:~
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy files to $REMOTE_IP_ADDRESS"
    exit 1
fi


# Make the setup.sh script executable and run it on the remote server
ssh root@$REMOTE_IP_ADDRESS "chmod +x ~/setup.sh"
if [ $? -ne 0 ]; then
    echo "Error: Failed to make setup.sh executable on $REMOTE_IP_ADDRESS"
    exit 1
fi

# Make the setup.sh script executable and run it on the remote server
ssh root@$REMOTE_IP_ADDRESS "./setup.sh"
if [ $? -ne 0 ]; then
    echo "Error: Failed to execute setup.sh on $REMOTE_IP_ADDRESS"
    exit 1
fi