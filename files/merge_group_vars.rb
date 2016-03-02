#!/bin/env ruby

require 'yaml'
require 'pp'

# Pick up the project name and the config.yml filename that the Vagrantfile kindly left for us
info = File.read("/home/vagrant/ansible_merge_info").chomp.split ':'

project_name=info[0]
config_file=info[1]


# Merge the config.yml that drove the Vagrant deploy with the group_vars in Ansible
config_vars = YAML.load_file "/vagrant/config.yml"
group_vars = YAML.load_file "/home/vagrant/ansible-oracle/group_vars/vagrant-RAC"

group_vars.merge!(config_vars)

File.open("/home/vagrant/ansible-oracle/group_vars/#{project_name}", 'w') {|f| f.write group_vars.to_yaml }

