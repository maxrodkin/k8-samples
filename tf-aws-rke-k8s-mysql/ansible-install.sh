#!/bin/bash
cd $1
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo yum -y install python3
sudo python3 get-pip.py
pip install virtualenv
virtualenv $1/myansible
. $1/myansible/bin/activate
pip install ansible docker requests
ansible --version


