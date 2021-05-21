#!/bin/bash -v
mkdir -p ~/.ssh

sudo yum -y install git
aws s3 cp s3://terraform-aws-enconnect/ssh/rodkin-nitka.pem ~/.ssh/
chmod 400 ~/.ssh/rodkin-nitka.pem

touch ~/.ssh/known_hosts
ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts

eval "$(ssh-agent -s)" && ssh-add ~/.ssh/rodkin-nitka.pem
cd $1
#git clone --single-branch --branch with-DB-creating  git@github.com:enVerid/ops.git
git clone --single-branch --branch master git@github.com:maximrdk/terraform-aws-enConnect.git



