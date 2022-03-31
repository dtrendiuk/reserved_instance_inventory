#!/bin/bash

tmp_dir=/tmp/reserved_instances_inventory

export AWS_ACCESS_KEY_ID=$RD_OPTION_AWS_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$RD_OPTION_AWS_SECRET_KEY
export AWS_DEFAULT_REGION=$RD_OPTION_AWS_REGION

inventory_list () {
region=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)
for region in $region
do
  aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone, Tags[?Key==`Name`]|[0].Value, InstanceId, InstanceType, State.Name]' \
  --region ${region} --output text >> ${tmp_dir}/List_Instances_Raw.csv;
  aws ec2 describe-reserved-instances \
  --filter Name=state,Values=active \
  --query 'ReservedInstances[*].[InstanceType, AvailabilityZone, InstanceCount, Start, End, State]' \
  --region ${region} --output text >> ${tmp_dir}/List_Reserved_Instances_Raw.csv
done
sed 's/\t/,/g' ${tmp_dir}/List_Instances_Raw.csv > ${tmp_dir}/List_Instances.csv
sed 's/\t/,/g' ${tmp_dir}/List_Reserved_Instances_Raw.csv > ${tmp_dir}/List_Reserved_Instances.csv
}

reserved_instances_inventory () {
region=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)
for region in $region
do
  list_expir_date=$(aws ec2 describe-reserved-instances \
  --filter Name=state,Values=active \
  --query 'ReservedInstances[*].[End]' --region ${region} --output text)
  current_date_sec=$(date +%s)
  timeago_sec=1209600

  for expir_date in $list_expir_date
  do
    expir_date_sec=$(date --date "$expir_date" +'%s')
    days_warning_before_sec=$((expir_date_sec-timeago_sec))
    if (( current_date_sec > days_warning_before_sec ))
    then
      for region in $region
      do
        aws ec2 describe-reserved-instances \
        --filter Name=state,Values=active \
        --query 'ReservedInstances[*].[InstanceType, AvailabilityZone, InstanceCount, Start, End, State]' \
        --region ${region} --output text | grep $expir_date >> ${tmp_dir}/List_Reserved_Instances_expir_Raw.csv
        echo "The reservation period has come to end, please check the list at: https://docs.google.com/spreadsheets/d/..."
      done
    fi
  done
done
if test -f ${tmp_dir}/List_Reserved_Instances_expir_Raw.csv; then
    sed 's/\t/,/g' ${tmp_dir}/List_Reserved_Instances_expir_Raw.csv > ${tmp_dir}/List_Reserved_Instances_expir.csv
fi
}

aws ec2 describe-regions --query "Regions[*].RegionName" --output table
if [ $? -eq 0 ]
then
  mkdir ${tmp_dir}
  inventory_list
  reserved_instances_inventory
  touch ${tmp_dir}/reserved-instances-inventory.json
  cat >> ${tmp_dir}/reserved-instances-inventory.json << EOT
{
google_service_account.json
}
EOT
else
  echo "The inventory list on $(date) was failed, check the issue!"
fi
