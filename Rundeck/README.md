# Reserved EC2 instance inventory (Rundeck project)

## Overview
This repo contains bash and python scripts which allow to:
- get a list of EC2 instances (from all regions) with inventory data (instance name, ID, type, state) and put it to Google spreadsheet;
- get a list reserved instances with inventory data (type, zone, count, stated date, expiries date, state) and put it to Google spreadsheet;
- send email notifications regarding the success/failure of the script working and with the links to Google spreadsheets with the results;
- send email notifications with the link to Google spreadsheets about reservation period ends in less than two weeks.

## Pre-Requisite
1. Access to AWS account.
2. SSH access to the Rundeck machine.
3. Create a Google Service Account and tweak it.
4. Access to the Rundeck admin panel.

## Preparations before the Rundeck job running.
### Register AWS user and create an IAM policy
Full instructions on this subject can be found at the official [Amazon AWS website](https://docs.aws.amazon.com/IAM/latest/UserGuide/id.html)

Create an IAM policy in accordance to `aws_user_policy.json` and add it to the User. Full instructions on this subject can be found at the official [Amazon AWS website](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_create.html)

Get AWS Access Key, AWS Secret Access Key and AWS Default Region IDs. Full instructions on this subject can be found at the official [Amazon AWS website](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)

In general you will need to export AWS Access Key, AWS Secret Access Key and AWS Default Region IDs of the created above user to the Rundeck job options before running the job.

Install `aws-cli` to the Rundeck server. Full instructions on how to do that can be found at the official [Amazon AWS website](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

### Create a Google Service Account
You will need to authenticate with Google to be able to interact with Google Sheets spreadsheets, using the concept of service accounts. The account will then need to be added as a collaborator to the sheet(s) you want to access.

Full instructions on how to create a Google Service Account can be found at the official [Google website](https://support.google.com/a/answer/7378726?hl=en).

In total you need to receive the credentials JSON file (and rename it to `reserved_instance_inventory.json`).

Create new [Google Spreadsheets](https://support.google.com/docs/answer/6000292?hl=en&co=GENIE.Platform%3DDesktop) and call them:
- List_Instances
- List_Reserved_Instances
- List_Reserved_Instances_expir

and share them for the `client_email` account from the above mentioned `reserved_instance_inventory.json`.

Take note of the ID of the Google Sheet document, which is contained in its URL, after the /d element. So, for example, if the URL of your document is https://docs.google.com/spreadsheets/d/1234567890123abcf/edit#gid=0, the ID will be 1234567890123abcf. You will need it to tweak Rundeck job further.

### Create a Rundeck project
Create a new [Rundeck project](https://docs.rundeck.com/docs/administration/projects/project-create.html#graphical-interface) with the following settings:
- Default Node Executor: Local
- Default Node File Copier: SCP
- Node Sources: Local

Install all the necessary Python libraries: `gspread`, `pathlib2`

## Steps to create and run Rundeck job
Create a [new job](https://docs.rundeck.com/docs/manual/creating-jobs.html#creating-a-job) with the following parameters:
1. add three [options](https://docs.rundeck.com/docs/manual/job-options.html#prompting-the-user):
- Option Type - Text
- Option Names - `aws_access_key`, `aws_secret_key`, `aws_region`
- Default Value - add relative values from AWS User ID
- Input Type - Plain Text
- all the rest items are set by default

2. Add five workflow steps one by one:
- `reserved_instance_inventory.sh`, in the following part instead of `google_service_account.json`
```
cat >> ${tmp_dir}/reserved-instances-inventory.json << EOT
{
google_service_account.json
}
EOT
```
paste the content of `reserved_instance_inventory.json` received above. And add the proper ID at the part `d/...`:
```
echo "The reservation period has come to end, please check the list at: https://docs.google.com/spreadsheets/d/..."
```

- `List_Instances` and add the proper ID at the part `d/...`:
```
print("Check the list of the instaces at: https://docs.google.com/spreadsheets/d/...")
```
- `List_Reserved_Instances` and add the proper ID at the part `d/...`:
```
print("Check the list of the reserved instances at: https://docs.google.com/spreadsheets/d/...")
```
- `List_Reserved_Instances_expir`
- `clear_details.sh`

3. Nodes - Execute locally

4. Send Notification? - Yes. Tweak notifications in accordance to your requirements.

5. Tweak the schedule in accordance to your requirements.

6. All other settings are set by default.

Run the job manually to make sure it works properly.
