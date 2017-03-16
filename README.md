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

## Templating: jinja2 features

http://jinja.pocoo.org/docs/dev/templates

```code
{%  %} for statements
{{ }} for expressions
{# #} for comments
# ## line statements
```

```code
{%  %} for statements
{{ }} for expressions
{# #} for comments
# ## line statements
```

### For loops

```code
{% for server in groups['webservers'] %}
  web{{ loop.index }}.tutorialinux.org
{% endfor %}
```

### Filters: predefined functions to be used in Jinja templates

* Display all the webservers in the inventory:

```code
{{ webservers|join(', ') }}
```

### Escaping

All these lines will be printed as they are, literally.

```code
{% raw %}
  <ul>
    {% for item in seq %}
      <li>{{ item }}</li>
    {% endfor %}
  </ul>
{% endraw %}
```

## YAML: Yet Another Markup Language

It's like JSON but with comments

```yml
---
# simple vars
name: David
video ideas: hundreds
free time: 0

# List (books = ["Cryptonomicon", "Snow Crash" ...])
books:
    - Cryptonomicon
    - Snow Crash
    - The Design and Implementation of the FreeBSD Operating System

# Dictionary ( languages = {"python": "excellent", "ruby": "good", ...})
languages:
    python: excellent
    ruby: good
    clojure: bad
    assembly: wannabe

# Multi-line string with new lines
hobbies: |
    4 GCSEs
    3 A-Levels
    BSc in the Internet of Things

# One long line
favorite_quote >
    I just love
    to read
    lots of books

# Quoting
# To do string interpolation, quotes are needed if variable is in the beginning (it's seen as a dictionary...)
# If the var is in the middle or at the end, it's fine without quotes.

vars:
  age_path: "{{ dave.age }}/html/oldman.html"
  age_path: /www/{{ dave.age }}/html/oldman.html
```

## Blocks

* New in ansible2

```yml
block:
  - name: First item
    command: "ls /somedir"
    rescue:
      - name: Only run when a task inside this block fails
        debug: msg="Somethig went wrong"
    always:
      - name: Always run
        debug: msg="Regardless of what happened above, we're onde with this block!"
```


## Ansible Galaxy

The ansible repository of roles:

* https://galaxy.ansible.com/

```shell
$ ansible-galaxy install username.rolename
$ ansible-galaxy install tutorialinux.nginx,v1.8.24
$ ansible-galaxy install git+https://github.com/groovemonkey/nginx.git
$ ansible-galaxy install -r requirements.yml # roles file
$ ansible-galaxy list => shows the locally already installed roles in /etc/ansible/roles
- jeqo.nginx, master => username=jeqo, rolename=nginx, version=master
$ ansible-galaxy remove username.rolename
```
### Example

* Using one role from galaxy:

```shell
$ sudo ansible-galaxy install jeqo.nginx => will install it in /etc/ansible/roles/jeqo.nginx
$ cd [my-project]/deploy/galaxy
$ ansible-playbook playbook.yml -i hosts -u ubuntu -k --ask-sudo-pass
```

