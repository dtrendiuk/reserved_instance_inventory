import os
import boto3

AMI = os.environ['AMI']
INSTANCE_TYPE = os.environ['INSTANCE_TYPE']
SUBNET_ID = os.environ['SUBNET_ID']
REGION = os.environ['REGION']

ec2 = boto3.client('ec2', region_name=REGION)


def lambda_handler(event, context):
    init_script = """#!/bin/bash
                sudo apt update -y
                sudo apt-get install ssmtp -y
                sudo bash -c 'cat >> /etc/ssmtp/ssmtp.conf << EOF
UseSTARTTLS=YES
FromLineOverride=YES
mailhub=smtp.gmail.com:587
AuthUser={email account}
AuthPass={email account password}
EOF'
                sudo apt install mailutils -y
                sudo apt-get install awscli -y
                git clone {path to the repository with bash script} /home/ubuntu/reserved_instance_inventory
                cd /home/ubuntu/reserved_instance_inventory && chmod +x reserved_instance_inventory.sh
                /home/ubuntu/reserved_instance_inventory/reserved_instance_inventory.sh
                sudo shutdown now
                """

    instance = ec2.run_instances(
        ImageId=AMI,
        InstanceType=INSTANCE_TYPE,
        SubnetId=SUBNET_ID,
        MaxCount=1,
        MinCount=1,
        InstanceInitiatedShutdownBehavior='terminate',
        IamInstanceProfile={'Name': 'ec2_readonly_role'},
        UserData=init_script
    )

    instance_id = instance['Instances'][0]['InstanceId']
    print(instance_id)

    return instance_id
