#!/bin/bash -v
mkdir -p ~/.ssh

sudo yum -y install git
aws s3 cp s3://ssh-rodkin-nitka/id_rsa ~/.ssh/
chmod 400 ~/.ssh/id_rsa

touch ~/.ssh/known_hosts
ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts

eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_rda

touch ~/.ssh/known_hosts
ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts

cd $1
git clone --single-branch --branch master git@github.com:maxrodkin/k8-samples.git



