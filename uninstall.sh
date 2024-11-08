#!/bin/bash

#******************************************************************************
# * @file           : uninstall.sh
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

USER_NME=$USER

cd ~
systemctl stop greengrass.service
systemctl disable greengrass.service
rm /etc/systemd/system/greengrass.service
systemctl daemon-reload && systemctl reset-failed
rm -rf /greengrass/v2

rm -rf /home/$USER_NME/GreengrassInstaller/