# Reserved EC2 instance inventory
Internal tasks [#141972](https://redmine.dev.pro/issues/141972)

## Overview
This repo contains bash script which allows to:
- get a list of EC2 instances (from all regions) with inventory data (instance name, ID, type, state);
- get a list reserved instances with inventory data (type, zone, count, stated date, expiries date, state);
- send email notifications regarding the success/failure of the script working and with attached spreadsheets with the results;
- send email notifications about that the reservation period ends in less than two weeks.

## Pre-Requisite
1. Access to AWS account (at least with EC2 Read-only access role).
2. Installed `aws cli` (if you run the script on your local machine).
3. Pre-installed `mailx` on the monitoring machine.

## Preparations before the script running.
### Register AWS user or create a role for the monitoring instance
Full instructions on this subject can be found at the official [Amazon AWS website](https://docs.aws.amazon.com/IAM/latest/UserGuide/id.html).

In general you need either to export AWS Access Key and AWS Secret Access Key IDs of the user with EC2 Read-only access role before running the script or to setup EC2 instance with the same EC2 Read-only access role.

Full instructions on how to install `aws cli` can be found at the official [Amazon AWS website](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

### Install and tweak mailx
Mailx is an intelligent mail processing system in Linux with good features to send and receive emails.

Ubuntu, Linux Mint, and other Debian Linux users run the below command to install mailutils package:
```
sudo apt install mailutils
```
Redhat/CentOS and Fedora Linux Distros run the below command to install mailx:
```
sudo yum install mailx
```
 SMTP server of a Gmail account is used in this tutorial (you can use any free SMTP server of any well-known email service provider). You need to select a Gmail account and enable the option of ‘Allow less secure apps’ for that account to send the email. You can visit the following [tutorial](https://support.google.com/accounts/answer/6010255?hl=en) to enable this option.

After enabling this option, you need to open the file `/etc/ssmtp/ssmtp.conf` with ‘root’ privilege and add the following lines at the end of the file. You need to set your email address to ‘AuthUser’ and your email password to ‘AuthPass’ to complete the setup:
```
UseSTARTTLS=YES
FromLineOverride=YES
root=admin@example.com
mailhub=smtp.gmail.com:587
AuthUser=username@gmail.com
AuthPass=password
```

## Steps to run the script

1. Upload this repo to your local machine or to the monitoring EC2 instance with the corresponding access. Make sure it has the execute permission:
```
chmod +x reserved_instance_inventory.sh
```

2. Add the email account to `reserved_instance_inventory.sh` script:
```
export CONTACT_EMAIL=your_contact@email.address
```

3. Add this script to cronjobs (in this example it will be running every day at 00:00:00):
```
0 0 * * * /path/to/the/script/reserved_instance_inventory.sh > /dev/null 2>&1
```
Run the script manually to make sure it works properly.
