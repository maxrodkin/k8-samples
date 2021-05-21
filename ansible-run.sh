#!/bin/bash
echo "ansible-run:"
chmod -R 777 $1

echo "pwd=$(pwd)"
#TODO!!! нужно избавиться от абсолютных путей
rm -f /opt/terraform-aws-enConnect/modules/aws/hosts
#aws s3 cp s3://terraform-aws-enconnect/ansible/hosts $1/
cp -f /opt/ops/ansible/container-deployment/hosts /opt/terraform-aws-enConnect/modules/aws/hosts
. $1/myansible/bin/activate
cd $1

#docker login...aws configure with role terraform-aws-enconnect
aws sts assume-role --role-arn arn:aws:iam::464048014215:role/terraform-aws-enconnect --role-session-name "terraform-aws-enconnect"  > assume-role-output.txt
export AWS_ACCESS_KEY_ID=$(grep AccessKeyId assume-role-output.txt|awk '{print $2}'|sed 's/"\|,//g') \
&& export AWS_SECRET_ACCESS_KEY=$(grep SecretAccessKey assume-role-output.txt|awk '{print $2}'|sed 's/"\|,//g') \
&& export AWS_SESSION_TOKEN=$(grep SessionToken assume-role-output.txt|awk '{print $2}'|sed 's/"\|,//g') \
&& export AWS_DEFAULT_REGION="us-west-2"

aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin 986941192896.dkr.ecr.us-west-2.amazonaws.com

#ansible-playbook -b -i ./hosts -l Staging --private-key ~/nitka/ssh/devops.pem -e 'ansible_python_interpreter=./myansible/bin/python' ./container-deployment.yml
ansible-playbook -b -i ./hosts -v -l from-TF  \
-e "ansible_python_interpreter=./myansible/bin/python" \
-e "hlr_message_queue_url=$hlr_message_queue_url" \
-e "hlr_debug_queue_url=$hlr_debug_queue_url" \
-e "hlr_session_events_queue_url=$hlr_session_events_queue_url" \
./container-deployment.yml

echo "hlr_message_queue_url=$hlr_message_queue_url"
