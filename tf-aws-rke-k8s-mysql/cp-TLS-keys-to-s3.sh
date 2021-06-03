#!/bin/bash -v
cd $1
export HOST_DNS_NAME=$(dig +short myip.opendns.com @resolver1.opendns.com|nslookup|awk 'NR==1{print $4}'|sed 's/.$//')
export HOST_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
echo $HOST_DNS_NAME
echo $HOST_IP
echo "Copy keys to S3:"
ls -la

aws s3 cp cert.pem s3://terraform-aws-enconnect/$HOST_DNS_NAME/cert.pem
aws s3 cp ca.pem s3://terraform-aws-enconnect/$HOST_DNS_NAME/ca.pem
aws s3 cp key.pem s3://terraform-aws-enconnect/$HOST_DNS_NAME/key.pem
