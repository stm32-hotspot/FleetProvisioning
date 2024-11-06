#!/bin/bash

#******************************************************************************
# * @file           : setup.sh
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

export ARG_GG_VERSION=2.13.0
export USER_NME=$USER
export GG_INSTALLER_PATH="/home/$USER_NME/GreengrassInstaller"


GG_FLEET_PLUGIN_VERSION=1.2.1


export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NOCOLOR='\033[0m'  # Reset to default color

gen_id()
{
  # Get the hostname
  HOSTNAME=$(hostname)
 
  # Generate a DUID (using the MAC address)
  DUID=$(cat /etc/machine-id)  # Alternatively, you can use MAC address: `ip link | awk '/ether/{print $2}'`
 
  # Combine hostname and DUID to create a unique device name
  DEVICE_NAME="${HOSTNAME}-${DUID}"  
}

install_dependecies()
{
  echo -e "${GREEN}Installing dependecies${NOCOLOR}"
  echo -e "${GREEN}This will take same time. Please do not turn off or restart your board${NOCOLOR}"

  # Install X-Linux-AWS
  echo -e "${YELLOW}update${NOCOLOR}"
  apt-get update
  echo -e "${YELLOW}install apt-openstlinux-x-linux-aws${NOCOLOR}"
  apt-get install apt-openstlinux-x-linux-aws -y
  echo -e "${YELLOW}update${NOCOLOR}"
  apt-get update
  echo -e "${YELLOW}install packagegroup-x-linux-aws${NOCOLOR}"
  apt-get install packagegroup-x-linux-aws -y
 
  # Uninstall Greengrass
  echo -e "${YELLOW}stop greengrass.service${NOCOLOR}"
  systemctl stop greengrass.service
  echo -e "${YELLOW}disable greengrass.service${NOCOLOR}"
  systemctl disable greengrass.service
  echo -e "${YELLOW}rm /etc/systemd/system/greengrass.service${NOCOLOR}"
  rm /etc/systemd/system/greengrass.service
  echo -e "${YELLOW}daemon-reload${NOCOLOR}"
  systemctl daemon-reload &&  systemctl reset-failed
  echo -e "${YELLOW}rm -rf /opt/greengrass/v2${NOCOLOR}"
  rm -rf /opt/greengrass/v2
  echo -e "${YELLOW}purge greengrass-bin${NOCOLOR}"
  apt-get purge greengrass-bin -y
 
  echo -e "${YELLOW}Remove all remnant files${NOCOLOR}"
  # Remove all remnant files
  find / -type f -name "*greengrass*" -exec  rm {} \;
  echo -e "${YELLOW}daemon-reload${NOCOLOR}"
  systemctl daemon-reload
  apt-get clean  
  echo -e "${GREEN}End Installing dependecies${NOCOLOR}"
}

# Install dependencies
install_dependecies

# create a unique ThingName
gen_id

echo -e "Greengrass Installer path : "${GREEN}$GG_INSTALLER_PATH${NOCOLOR}
echo -e "ThingName : "${GREEN}$DEVICE_NAME${NOCOLOR}

# Update the config file
# Update ThingName
sed -i 's|"ThingName": "[^"]*"|"ThingName": "'"$DEVICE_NAME"'"|' config.json
sed -i 's|"version": "[^"]*"|"version": "'"$ARG_GG_VERSION"'"|' config.json

# Make GG root directory
mkdir -p /greengrass/v2
chmod 755 /greengrass
 
# Copy claim certs to GG root directory
cp -r ./claim-certs /greengrass/v2/claim-certs

# Download Amazon RootCA to GG root directory
curl -o /greengrass/v2/AmazonRootCA1.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem

# Create user and group
useradd --system --create-home ggc_user
groupadd --system ggc_group

echo -e "${GREEN}Download greengrass installer${NOCOLOR}"
# Download and unzip greengrass installer
curl -s https://d2s8p88vqu9w66.cloudfront.net/releases/greengrass-$ARG_GG_VERSION.zip > greengrass-nucleus-latest.zip

echo -e "${GREEN}Unzip greengrass installer${NOCOLOR}"
unzip greengrass-nucleus-latest.zip -d $GG_INSTALLER_PATH && rm greengrass-nucleus-latest.zip

echo -e "${GREEN}Download fleet provisioning plugin${NOCOLOR}"
# Download fleet provisioning plugin
# curl -s https://d2s8p88vqu9w66.cloudfront.net/releases/aws-greengrass-FleetProvisioningByClaim/fleetprovisioningbyclaim-latest.jar > $GG_INSTALLER_PATH/aws.greengrass.FleetProvisioningByClaim.jar
curl -s https://d2s8p88vqu9w66.cloudfront.net/releases/aws-greengrass-FleetProvisioningByClaim/fleetprovisioningbyclaim-$GG_FLEET_PLUGIN_VERSION.jar > $GG_INSTALLER_PATH/aws.greengrass.FleetProvisioningByClaim.jar

# Copy config file
cp ./config.json $GG_INSTALLER_PATH/config.json

echo -e "${GREEN}Run installer and FleetProvisioningByClaim${NOCOLOR}"
# Run installer
sudo -E java -Droot="/greengrass/v2" -Dlog.store=FILE \
  -jar $GG_INSTALLER_PATH/lib/Greengrass.jar \
  --trusted-plugin $GG_INSTALLER_PATH/aws.greengrass.FleetProvisioningByClaim.jar \
  --init-config $GG_INSTALLER_PATH/config.json \
  --component-default-user ggc_user:ggc_group \
  --setup-system-service true
 
# Delete GreengrassInstaller
rm -rf $GG_INSTALLER_PATH/

# Delete Claim Certificates
rm -rf ./claim-certs