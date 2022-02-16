#!/bin/bash
export CONTACT_EMAIL=trendjuk@gmail.com

## first function gathers the list and sends email notifications about all EC2 instances (reserved and on-demand)
inventory_list () {
region=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)
for region in $region
do
  # gathers all on-demand EC2 instances and sends the list to List_Instances.csv
  aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone, Tags[?Key==`Name`]|[0].Value, InstanceId, InstanceType, State.Name]' \
  --output text --region ${region} >> List_Instances.csv;
  # gathers all reserved EC2 instances and sends the list to List_Reserved_Instances.csv
  aws ec2 describe-reserved-instances \
  --query 'ReservedInstances[*].[InstanceType, AvailabilityZone, InstanceCount, Start, End, State]' \
  --region ${region} --output text >> List_Reserved_Instances.csv
done
# sends .csv files to contact email address
echo "The inventory on $(date) was successful, the list of instances is attached" \
| mail -s "List_Instances" -A ./List_Instances.csv -A ./List_Reserved_Instances.csv $CONTACT_EMAIL;
rm List_Instances.csv List_Reserved_Instances.csv
}

## second function checks expiration period and sends email notifications if the reservation period ends in two weeks
reserved_instances_inventory () {
region=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)
for region in $region
do
  # filter expiration date of active reserved instances
  list_expir_date=$(aws ec2 describe-reserved-instances \
  --filter Name=state,Values=active \
  --query 'ReservedInstances[*].[End]' --region ${region} --output text)
  current_date_sec=$(date +%s) # defines current date
  timeago_sec=1209600 # 14 days in sec

  for expir_date in $list_expir_date
  do
    # defines expiration date in sec
    expir_date_sec=$(date --date "$expir_date" +'%s')
    # defines 14 days before expiration date in sec
    days_warning_before_sec=$((expir_date_sec-timeago_sec))
    if (( current_date_sec > days_warning_before_sec ))
    then
      for region in $region
      do
        # gathers one by one reserved EC2 instances and sends the list to List_Reserved_Instances.csv
        aws ec2 describe-reserved-instances \
        --filter Name=state,Values=active \
        --query 'ReservedInstances[*].[InstanceType, AvailabilityZone, InstanceCount, Start, End, State]' \
        --region ${region} --output text | grep $expir_date >> List_Reserved_Instances.csv;
        echo "The reservation period has come to end, please check the list." \
        | mail -s "AWS reservation period ends in less than two weeks!" -A ./List_Reserved_Instances.csv $CONTACT_EMAIL;
        rm List_Reserved_Instances.csv
      done
    else
      echo "Everything is fine."
    fi
  done
done
}

# checks AWS availability and whether list of the regions can be received
aws ec2 describe-regions --query "Regions[*].RegionName" --output text
if [ $? -eq 0 ]
then
  inventory_list
  reserved_instances_inventory
else
  echo "The inventory list on $(date) was failed, check the issue!" | mail -s "Failed inventory list" $CONTACT_EMAIL
fi
