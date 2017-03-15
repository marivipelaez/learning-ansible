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

### Add keys

Following https://help.ubuntu.com/community/SSH/OpenSSH/Keys


```shell
$ ssh-keygen -t rsa
$ cat .ssh/id_rsa.pub >> .ssh/authorized_keys
$ ssh-add
  Identity added: /home/vagrant/.ssh/id_rsa (/home/vagrant/.ssh/id_rsa)
$ ssh-add -L
```

Add your brand-new ssh key to your hosts:

```shell
$ ssh-copy-id ubuntu@10.0.3.30
```

Check that everything works like a charm:

```shell
$ ansible 10.0.3.19 -m ping -u root -i inventory
10.0.3.19 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Use ansible to install new packages and check them
```shell
$ ansible web -a "apt-get update" -i inventory -u root
$ ansible web -a "apt-get -y install nginx" -i inventory -u root
$ ansible web -m service -a "name=nginx state=restarted" -i inventory -u root
```

Add this section to your `ansible.cfg` to be able to become root:

```yml
[privilege_escalation]
become=Yes
become_method=sudo
become_user=root
become_ask_pass=True
```

## Using playbooks

### Playbook to prepare a host for ansible :)

Different ways of copying ssh key to each machine:

* Using ansible module autorized_key

```yml
    - name: Fancy way of doing authorized keys
      authorized_key: user=root
                      exclusive=no
                      key="{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
```

* Creating /root/.ssh and copying our pubkey:

```yml
    - name: Create /root/.ssh
      file: path=/root/.ssh/ state=directory mode=0700

    - name: Copy pubkey to authorized_keys
      lineinfile: dest=/root/.ssh/authorized_keys line="{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
```

### Playbooks
`$ ansible-playbooks playbook.yml --connection=local` => to run only in the local server

### Modules
http://docs.ansible.com/ansible/list_of_all_modules.html

* OS package system: Use `package` instead of `apt`, `yum`, `pkg` or `apt_repository`
* files: `template, file, lineinfile, blockinfile, copy, fetch, stat`
* System: `service, user, group, cron, hostname, authorized_key, iptables, modprobe, kernel_blacklist, gluster_volume, lvm, zfs`
* Various: `raw, synchronize, get_url, unarchive, ec2, rds`

### Variables & Facts
* Scopes: Global, Per-Play, Per-Host, `--extra-vars` flag overrides everything
* Get all facts from a host:

`$ ansible 10.0.3.213 -i inventory -m setup -u root`

## Troubleshooting

* In the happening of an error with ssh authentication:
`export ANSIBLE_HOST_KEY_CHECKING=False`

* To prepare a host to be managed with ansible use this line `gather_facts=False` to avoid needing python before installing it.

* Module `debug` with msg or var to analyze errors

* Module `stat` to know the status of a file/folder
* Module `shell` to run basic linux commands (for instance, `whoami`)


## Control status in raw commands

* Changed_when:

```yml
- command: "apt-get upgrade -y"
  register: apt_upgrade
  changed_when: "'0 upgraded, 0 newly installed' not in apt_upgrade.stdout"
```

* failed_when:

 Control when a raw command failed:

```yml
- command: "ls /some/nonexistent/directory"
  register: mylisting
  failed_when: "'foo' not in mylisting.stderr"
```

* ignore_errors:

Used when a task is likely to produce errors in STDOUT, they can be ignored:

```yml
- command: "ls /some/nonexistent/directory"
  register: mylisting
  failed_when: "'foo' not in mylisting.stderr"
  ignore_errors: yes
```

* something is/is not defined


```yml
- name: Check if my_var is defined
  debug: msg="Yes, my_var is defined"
  when: my_var is defined
```

