
# Fleet Provisioning for AWS IoT Greengrass on STM32MP1 and STM32MP2

## Overview
This project provides an automated setup for AWS IoT Fleet Provisioning with Greengrass V2 on STM32MP1/STM32MP2 devices. By using CloudFormation, claim certificates, and an IoT provisioning template, this project enables scalable, secure, and automated provisioning of IoT devices, allowing them to self-register and maintain secure communication through AWS IoT.

## Prerequisites
- **[STM32MP135F-DK](https://www.st.com/en/evaluation-tools/stm32mp135f-dk.html) or [STM32MP257F-DK](https://www.st.com/en/evaluation-tools/stm32mp257f-dk.html)** : The device must be set up and [accessible over the network](https://wiki.st.com/stm32mpu/wiki/How_to_setup_a_WLAN_connection).
- **[X-LINUX-AWS](https://wiki.st.com/stm32mpu/wiki/X-LINUX-AWS_Starter_package)**: Ensure that X-LINUX-AWS is installed on the STM32MP1/MP2.
- **AWS Account**: Access to an AWS account with permissions to manage IAM, IoT, Greengrass, and CloudFormation stacks.
- **[AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)**: Install and [configure](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html) the AWS CLI on your local machine.
- **[Git Bash](https://git-scm.com/downloads)**: Required for Windows users to provide a Unix-like shell compatible with the scripts.
- **SSH Access**: Ensure SSH access to the STM32MP1/MP2.

## Files

1. **createFleetProvisioningStack.sh**
   - Creates the required CloudFormation stack to provision resources in AWS for IoT Greengrass and Fleet Provisioning.

2. **updateConfig.sh**
   - Parses `template.yaml` and uses AWS CLI to collect and create required fields, automatically populating `config.json`.

3. **execute.sh**
   - Copies necessary files to the STM32MP1/MP2 device and runs `setup.sh` remotely.

4. **setup.sh**
   - Configures AWS IoT Greengrass V2 with Fleet Provisioning, generates a unique device name, installs dependencies, and sets up the Greengrass core device.

5. **uninstall.sh**
   - Stops and removes Greengrass installation and configuration files from the system.
   - Must be run on the MPU

6. **config.json**
   - Configuration file for AWS IoT Greengrass and Fleet Provisioning, holding AWS region, claim certificate paths, endpoints, and provisioning details.

7. **template.yaml**
   - CloudFormation template for provisioning Greengrass and Fleet Provisioning resources.

8. **deviceCleanup.sh**
   - Cleans up IoT resources by deleting the IoT Thing, its certificates, and Greengrass core device.

---

## Setup Steps

### 1. Clone this Repository
On a PC with AWS CLI installed, clone this repository:

```bash
git clone https://github.com/stm32-hotspot/FleetProvisioning
cd FleetProvisioning
```

### 2. Create the CloudFormation Stack
Use `createFleetProvisioningStack.sh` to automte the setup of AWS IoT Fleet Provisioning by creating a CloudFormation stack, generating claim certificates, and attaching the necessary IoT policies.

```bash
./createFleetProvisioningStack.sh -s <STACK_NAME>
```
> Note: AWS CloudFormation Stack template can be modified in `template.yaml` 
### 3. Generate Required Configuration
Run `updateConfig.sh` to parse `template.yaml` and populate `config.json` with required AWS endpoint and configuration data:

```bash
./updateConfig.sh -g <THING_GROUP_NAME>
```

Replace `<THING_GROUP_NAME>` with the desired name for your Thing Group. This step automatically updates `config.json` with:
   - AWS Region
   - Thing Group Name
   - IoT Credential and Data endpoints
   - Role Alias and Provisioning Template values from `template.yaml`

### 4. Install Greengrass and Provision STM32MP1/MP2
The `execute.sh` script will handle file transfer and initiate setup on the board:

```bash
./execute.sh -i <Board.IP.ADDRESS>
```

Replace `<Board.IP.ADDRESS>` with your STM32MP1/MP2 device’s IP. This step:
   - Copies all necessary files to the STM32MP1/MP2.
   - SSHs into the board and runs `setup.sh`.

> Note: This is the only script that will need to be ran once for every board.

### 5. Verify Greengrass Core Device Status
To confirm your device is set up and registered as a Greengrass core device:

```bash
aws greengrassv2 list-core-devices --status HEALTHY
```

### 6. (Optional) Uninstall Greengrass
To remove AWS IoT Greengrass from your device, run `uninstall.sh` on the MPU:

```bash
chmod +x uninstall_greengrass.sh
./uninstall.sh
```

> Note: to ssh to MPU use the following command: `ssh root@<BOARD.IP.ADDRESS>`

---
## Troubleshooting
If issues arise, consider the following:
   - **Network Connectivity**: Ensure device connectivity to AWS IoT endpoints.
   - **IAM Permissions**: Verify permissions for IoT, Greengrass, and CloudFormation.
   - **Certificates and Policies**: Confirm that the claim certificate and policies are correctly set up.
   - **Supported Region**: Ensure that your AWS Region supports Greengrass V2. A list of supported regions can be found in the [AWS Greengrass documentation](https://docs.aws.amazon.com/general/latest/gr/greengrass.html#greengrass_region).
   - **Viewing Logs**: For troubleshooting Greengrass issues on the device, check the Greengrass logs located in `/greengrass/v2/logs/`.
