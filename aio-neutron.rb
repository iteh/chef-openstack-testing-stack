require 'chef_metal_ssh'

with_ssh_cluster("~/metal_ssh")

machine "controller" do
  action [:ready, :converge]
  machine_options 'ip_address' => '192.168.1.6', 'ssh_options' => {
    'user' => 'root',
    'password' => 'secret'
  }
  role 'allinone-compute'
  role 'os-image-upload'
  recipe 'openstack-common::openrc'
  chef_environment 'vagrant-aio-neutron'
  file '/etc/chef/openstack_data_bag_secret',"#{File.dirname(__FILE__)}/.chef/encrypted_data_bag_secret"
  converge true
end