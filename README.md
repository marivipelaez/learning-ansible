# ANSIBLE 2 FOR BEGINNERS

Following the course: https://www.safaribooksonline.com/library/view/ansible-2-for/9781786465719

## Setting up the environment

`vagrant up --provision`
`vagrant ssh`

### Using lxc containers

```shell
# lxc-create -n db1 -t ubuntu
# lxc-create -n web1 -t ubuntu
# lxc-create -n web2 -t ubuntu
# lxc-ls -f
NAME  STATE    IPV4  IPV6  AUTOSTART
------------------------------------
db1   STOPPED  -     -     NO
web1  STOPPED  -     -     NO
web2  STOPPED  -     -     NO

# lxc-start -n db1 -d
# lxc-ls -f
NAME  STATE    IPV4       IPV6  AUTOSTART
-----------------------------------------
db1   RUNNING  10.0.3.30  -     NO
web1  STOPPED  -          -     NO
web2  STOPPED  -          -     NO
```

### Install python 2.7 in lxc containers

```
# lxc-attach -n db1
# apt-get install python-minimal --no-install-recommends
```

## Ansible configuration

* Ansible_Config (environment variable)
* ansible.cfg (current directory)
* .ansible.cfg (user's home)
* /etc/ansible/ansible.cfg

## Ansible hosts

* Default file in `/etc/ansible/hosts`
* Include a new inventory file per project (INI syntax) to be used as:

```shell
# ansible-playbook -i inventory ....
```
