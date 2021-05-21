#!/bin/bash -v

#####################modules/aws/clone-git-repo.sh##########################
mkdir -p ~/.ssh

sudo yum -y install git
aws s3 cp s3://terraform-aws-enconnect/ssh/rodkin-nitka.pem ~/.ssh/
chmod 400 ~/.ssh/id_rsa

touch ~/.ssh/known_hosts
ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts

eval "$(ssh-agent -s)" && ssh-add ~/.ssh/rodkin-nitka.pem

workdir="/opt" && cd $workdir
git clone  --single-branch --branch master  git@github.com:enVerid/ops.git
git clone git@github.com:maximrdk/terraform-aws-enConnect.git
#git clone --single-branch --branch split-to-modules git@github.com:maximrdk/terraform-aws-enConnect.git

#####################modules/aws/clone-git-repo.sh##########################
run-script () {
  cd $workdir && echo "workdir=$workdir" && echo "pwd=$(pwd)"
  chmod +x $filename
  $filename $workdir
}

filename="/opt/terraform-aws-enConnect/modules/aws/swap-on.sh"
run-script

filename="/opt/terraform-aws-enConnect/modules/aws/docker-install.sh"
run-script

workdir="/opt/docker-TLS" && mkdir -p $workdir $$ chmod 644 $workdir  && cd $workdir
filename="/opt/terraform-aws-enConnect/modules/aws/add-TLS-to-docker.sh"
run-script

