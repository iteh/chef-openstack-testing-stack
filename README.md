# OpenStack-cluster with chef-provisioning

This is the testing framework for OpenStack and Chef. We leverage this to test against our changes to our cookbooks to make sure
that you can still build a cluster from the ground up with any changes we push up. This will eventually be tied into the gerrit workflow
and become a stackforge project.

This framework also gives us an opportunity to show different Reference Architectures and a sane example on how to start with OpenStack and Chef.

At this moment in time we've only tested this with CentOS 6.5 and soon CentOS 7.0 with our `stable/icehouse` branches, but `master` and the `stable/juno`
branch will be quickly following. Ubuntu 14.04 support is on hold until the Chef-client 12 is released to deal with some of the
service restarting issues.

## Prereqs

- at least Vagrant 1.6.3
- Virtualbox or something like that that vagrant can use
- a sane Ruby environment

## Steps

```shell
$ vagrant add centos65 http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.5_chef-provisionerless.box
$ git clone https://github.com/jjasghar/chef-openstack-testing-stack.git testing-stack
$ cd testing-stack
$ bundle install
$ bundle exec berks vendor cookbooks
$ ruby -e "require 'openssl'; puts OpenSSL::PKey::RSA.new(2048).to_pem" > .chef/validator.pem
$ export CHEF_DRIVER=vagrant
```
This has also been tested with ChefDK 0.3.5. Simply omit the `bundle install` command and any `bundle exec` prefixes.

You need four databags : *user_passwords*, *db_passwords*, *service_passwords*, *secrets*. I have a already created
the `data_bags/` directory, so you shouldn't need to make them, if you do something's broken.

You may also need to change the networking options around the `aio-nova.rb`, `aio-neutron.rb`, `multi-nova.rb` or `multi-neutron.rb` files. I wrote this on
my MacBook Pro with an `en0` you're mileage may vary.

Now you should be good to start up `chef-client`!

```bash
$ bundle exec chef-client -z vagrant_linux.rb aio-nova.rb
```
or
```bash
$ bundle exec chef-client -z vagrant_linux.rb aio-neutron.rb # still not complete
```
If you want a multi-node cluster:
```bash
$ bundle exec chef-client -z vagrant_linux.rb multi-nova.rb
```
or
```bash
$ bundle exec chef-client -z vagrant_linux.rb multi-neutron.rb  # still not complete
```
If you spin up one of the multi-node builds, you'll have four machines `controller`,`compute1`,`compute2`, and `compute3`. They all live on the
`192.168.100.x` network so keep that in mind. If you'd like to take this and change it around, whatever you decide your controller
node to be change anything that has the `192.168.100.60` address to that.

NOTE: We also have plans to split out the `multi-neutron-network-node` cluster also so the network node is it's own machine.
This is also `still not complete`.

```bash
$ cd vms
$ vagrant ssh controller
$ sudo su -
# source openrc
```

How to test the machine is set up correctly, after you source the above: (as root)

```bash
# nova service-list && nova hypervisor-list && nova image-list
```

Boot that image! (as root)

```bash
# nova boot test --image cirros --flavor 1
```

If you would like to use the dashboard you should go to https://localhost:9443 and the username and password is `admin/mypass`.

If you want to destroy everything, run this from the `testing-stack/` repo.

```bash
$ chef-client -z destroy_all.rb
```

## Running Juno on Ubuntu 14.04

To run Juno on Ubuntu 14.04 you need to make two manual changes your Chef Run:

### Use Chef 12 RC1

Until the official release of Chef 12 you need to resort to it's Release Candidate. Without it, you will run into problems with starting rabbitmq and all OpenStack services. The problem is caused by Ubuntu's switch to Upstart to start services (http://en.wikipedia.org/wiki/Upstart) on recent Ubuntu releases.

* Run the chef-client until it fails (we need the basic machine created)
* Install Chef 12 RC1 on the Vagrant machine:

```
# Inside the chef-openstack-testing-stack project
cd vms
vagrant ssh

# On the Vagrant machine
sudo apt-get install curl
curl -L https://www.getchef.com/chef/install.sh | sudo bash -s -- -v 12.0.0.rc.1
```

* Exit the Vagrant machine ( ctrl + d )
* Re-run chef-client

This fix will not be necessary as soon as Chef 12 is officially released and is made available as "latest" Chef version.

### Fixing the Dashboard 

```
# Inside the chef-openstack-testing-stack project
cd vms
vagrant ssh

# On the Vagrant machine
cd /etc/apache2/sites-available
sudo mv openstack-dashboard openstack-dashboard.conf
sudo a2ensite openstack-dashboard.conf
sudo service apache2 reload
sudo service apache2 restart
```

You can now access the dashboard in your browser.
