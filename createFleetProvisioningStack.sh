#!/bin/bash

#******************************************************************************
# * @file           : FleetProvisioning.sh
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

# Define the CloudFormation stack name
# Define the YAML file
TEMPLATE_FILE="template.yaml"

# Function to display help
usage() {
    echo "Usage: $0 -s STACK_NAME"
    exit 1
}

# Parse command line arguments
while getopts ":s:" opt; do
    case ${opt} in
        s )
            STACK_NAME=$OPTARG
            ;;
        \? )
            usage
            ;;
    esac
done

# Check that the stack name argument is provided
if [ -z "$STACK_NAME" ]; then
    usage
fi

# Define output file paths
CERT_DIR="claim-certs"
CERT_PEM_OUTFILE="$CERT_DIR/claim.pem.crt"
PUBLIC_KEY_OUTFILE="$CERT_DIR/claim.public.pem.key"
PRIVATE_KEY_OUTFILE="$CERT_DIR/claim.private.pem.key"

# Create the CloudFormation stack
echo "Creating CloudFormation stack: $STACK_NAME..."
aws cloudformation create-stack --stack-name $STACK_NAME --template-body file://$TEMPLATE_FILE --capabilities CAPABILITY_NAMED_IAM

# Check the creation status
echo "Waiting for CloudFormation stack creation to complete..."
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME

# Verify the stack status
STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].StackStatus" --output text)
if [ "$STATUS" == "CREATE_COMPLETE" ]; then
    echo "CloudFormation stack $STACK_NAME created successfully."
else
    echo "Error: Stack $STACK_NAME creation failed with status: $STATUS"
    exit 1
fi

# Create the claim-certs directory if it doesn't exist
mkdir -p $CERT_DIR

# Step 1: Create the certificate and keys
echo "Creating certificate and keys..."
CERT_ARN=$(aws iot create-keys-and-certificate \
  --certificate-pem-outfile "$CERT_PEM_OUTFILE" \
  --public-key-outfile "$PUBLIC_KEY_OUTFILE" \
  --private-key-outfile "$PRIVATE_KEY_OUTFILE" \
  --set-as-active \
  --query 'certificateArn' \
  --output text)

if [ -z "$CERT_ARN" ]; then
    echo "Error: Failed to create certificate."
    exit 1
else
    echo "Certificate created successfully with ARN: $CERT_ARN"
fi

# Extract the default values for ProvisioningTemplateName and GGTokenExchangeRoleName from template.yaml
POLICY_NAME=$(grep -A 2 "GGProvisioningClaimPolicyName:" $TEMPLATE_FILE | grep "Default:" | awk '{print $2}' | tr -d "'")

echo "POLICY_NAME : "$POLICY_NAME

# Check if values were found
if [ -z "$POLICY_NAME" ]; then
    echo "Failed to extract Policy Name from $TEMPLATE_FILE."
    exit 1
fi

# Step 2: Attach the IoT policy to the claim certificate
echo "Attaching policy $POLICY_NAME to the certificate..."
aws iot attach-policy --policy-name "$POLICY_NAME" --target "$CERT_ARN"

if [ $? -eq 0 ]; then
    echo "Policy $POLICY_NAME successfully attached to certificate."
else
    echo "Error: Failed to attach policy."
    exit 1
fi

echo "Certificate and policy setup completed."



