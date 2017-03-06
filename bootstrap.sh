#!/usr/bin/env bash

# INSTALL DEPENDENCIES
apt-add-repository ppa:ansible/ansible
apt-get update
apt-get install -y software-properties-common
apt-get install -y ansible
apt-get install -y lxc
apt-get autoremove

# CREATE LXC CONTAINERS
lxc-create -n db1 -t ubuntu
lxc-create -n web1 -t ubuntu
lxc-create -n web2 -t ubuntu

# START LXC CONTAINERS AS DAEMONS
lxc-start -n db1 -d
lxc-start -n web1 -d
lxc-start -n web2 -d