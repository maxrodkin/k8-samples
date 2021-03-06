#!/bin/bash -v

sudo yum install ec2-instance-connect

#####################modules/aws/clone-git-repo.sh##########################
mkdir -p ~/.ssh

sudo yum -y install git
aws s3 cp s3://ssh-rodkin/id_rsa ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa

touch ~/.ssh/known_hosts
ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts

eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_rsa

touch ~/.ssh/known_hosts
ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts

workdir="/opt" && cd $workdir
git clone --single-branch --branch master git@github.com:maxrodkin/k8-samples.git

#####################modules/aws/clone-git-repo.sh##########################
run-script () {
  cd $workdir && echo "workdir=$workdir" && echo "pwd=$(pwd)"
  chmod +x $filename
  $filename $workdir
}

filename="k8-samples/swap-on.sh"
run-script

filename="k8-samples/docker-install.sh"
run-script

sudo usermod -aG docker ec2-user

#workdir="/opt/docker-TLS" && mkdir -p $workdir $$ chmod 644 $workdir  && cd $workdir
#filename="/opt/terraform-aws-enConnect/modules/aws/add-TLS-to-docker.sh"
#run-script

