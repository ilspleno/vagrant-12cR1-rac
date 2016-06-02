# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Read configuration file
config_file = ENV['CONFIG_FILE'] || "config.yml"
if File.exist? config_file
	@cfg = YAML.load_file(config_file)	
else
	puts "Config file doesn't exist!"
	exit 1
end

# Create an /etc/hosts file that can be provisioned to each host
$hosts  = "#!/bin/bash\ncat > /etc/hosts << EOF\n127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4\n"
$hosts += "::1         localhost6 localhost6.localdomain6\n"

# Normal hostnames and vips
(1..@cfg[:node_count]).each do |p|

	tmp_node_name="#{@cfg[:node_name]}#{p if @cfg[:node_count] > 1}"

	$hosts += "#{@cfg[:public_prefix]}.#{@cfg[:public_offset]+p}\t#{@cfg[:node_name]}#{p if @cfg[:node_count] > 1}\n"

	# Only add vip and priv if this is a RAC install
	if @cfg[:node_count] > 1
		$hosts += "#{@cfg[:public_prefix]}.#{@cfg[:vip_offset]+p}\t#{@cfg[:node_name]}#{p}-vip\n"
		$hosts += "#{@cfg[:private_prefix]}.#{@cfg[:private_offset]+p}\t#{@cfg[:node_name]}#{p}-priv\n"
	end
	$hosts += "\n"
end

# Add scan addresses if a RAC
if @cfg[:node_count] > 1
	(1..3).each do |n|
		$hosts += "#{@cfg[:public_prefix]}.#{@cfg[:scan_offset]+n}\t#{@cfg[:project_name]}-scan\n"
	end
end

# End the HOSTS script
$hosts += "EOF\n"

# Create an ansible inventory file based on the hosts generated
$ansible = "#!/bin/bash\ncat > /home/vagrant/#{@cfg[:project_name]} << EOF\n"
$ansible += "[#{@cfg[:project_name]}]\n"
(1..@cfg[:node_count]).each do |p|
	$ansible += "#{@cfg[:node_name]}#{p if @cfg[:node_count] > 1}\n"
end
$ansible += "EOF\n"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

	config.vm.box = "ilspleno/centos-6-7-puppet-oracle-base"

	# Borrowing heavily from https://github.com/oravirt/vagrant-vbox-rac/blob/master/Vagrantfile for the looping in reverse creation
	
	(1..@cfg[:node_count]).each do |node_num|

		# Invert the order so that node 1 goes last. Once node 1 is available we can begin install
		node_num = @cfg[:node_count] + 1 - node_num

		this_node_name = "#{@cfg[:node_name]}#{node_num if (@cfg[:node_count] > 1)}"
		config.vm.define this_node_name do |node|

			node.vm.hostname = this_node_name

			# Network config
			node.vm.network :private_network, ip: "#{@cfg[:public_prefix]}.#{@cfg[:public_offset]+node_num}"
			node.vm.network :private_network, ip: "#{@cfg[:private_prefix]}.#{@cfg[:private_offset]+node_num}"

			node.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
			node.vm.synced_folder @cfg[:software_location], "/software", :mount_options => ["dmode=755","fmode=755"]

			node.vm.provider :virtualbox do |vb|
				vb.customize ["modifyvm"     , :id, "--memory" , @cfg[:memory]]
				vb.customize ["modifyvm"     , :id, "--name"   , this_node_name]
				vb.customize ["modifyvm"     , :id, "--cpus", @cfg[:cpus]]

				# Allocate disks
				
				diskport = 1
				diskpath=`VBoxManage list systemproperties | grep "Default machine folder" | awk ' { print $4; } '`.chomp
	

				@cfg["asm_diskgroups"].each do |dg|

					(1..dg["disk"].count).each do |n|

						
						if !ENV['OS'].nil? and (ENV['OS'].match /windows/i)
							disk = diskpath + "\\#{@cfg[:node_name]}_#{dg["diskgroup"]}_#{n}.vdi"
					                        else
			                                disk = diskpath + "/#{@cfg[:node_name]}_#{dg["diskgroup"]}_#{n}.vdi"
                       				end
						
						# Don't make fully allocated disks unless we have to for sharing
						if @cfg[:node_count] > 1
							variant = "Fixed"
						else
							variant = "Standard"
						end

						if (node_num == @cfg[:node_count]) and (!File.exist?(disk.gsub /\\\\/, '\\'))
                                			# Create the disks
			                              	vb.customize ['createhd', '--filename', disk, '--size', dg["disksize"] * 1024, '--variant', variant]

							# Mark shareable if multi-node
				                        vb.customize ['modifyhd', disk, '--type', 'shareable'] if (@cfg[:node_count] > 1)
						end
                                 		
						# Either way attach the disk
                                                vb.customize ['storageattach', :id,  '--storagectl', 'SATA Controller', '--device', 0, '--port', diskport, '--type', 'hdd', '--medium', disk]
						diskport += 1

					end # Create diskgroup disks

				end # each diskgroup

			end # virtualbox provider

			# common provisioning
			node.vm.provision "shell", inline: <<-SHELL
				cp -v /vagrant/files/id_rsa* /home/vagrant/.ssh
				chown vagrant:vagrant /home/vagrant/.ssh/id_rsa
				cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
				chmod 600 /home/vagrant/.ssh/id_rsa*
			SHELL


			# Update node hostfile
			node.vm.provision "shell", inline: $hosts

			# Extra provisioning for node 1
			if (node_num == 1)
					
				node.vm.provision "shell", inline: <<-SHELL
					yum -y install ansible ruby
					cd /home/vagrant && git clone -b 12cR1-rac https://github.com/ilspleno/ansible-oracle.git
					chown -R vagrant:vagrant /home/vagrant/ansible-oracle	
				SHELL
			
				# Create ansible inventory
				node.vm.provision "shell", inline: $ansible

				# Create host_vars and merge group_vars
				(1..@cfg[:node_count]).each do |n|
					mn_state = "false"
					mn_state = "true" if n == 1
					node.vm.provision "shell", inline: <<-SHELL
						su - vagrant -c 'echo "---\n\n  master_node: #{mn_state}\n" > ~/ansible-oracle/host_vars/#{@cfg[:node_name]}#{n if @cfg[:node_count] > 1} ;
							echo "#{@cfg[:project_name]}:#{config_file}" > ~/ansible_merge_info ;
							/vagrant/files/merge_group_vars.rb ;
							cd ~/ansible-oracle && sed " s/PROJECTNAME/#{@cfg[:project_name]}/g " vagrant-RAC.yml > #{@cfg[:project_name]}.yml
						'
					SHELL
						
				end

#				node.vm.provision "shell", inline: <<-SHELL
#					nohup su - vagrant -c "cd ansible-oracle && ansible-playbook -i ../#{@cfg[:project_name]} #{@cfg[:project_name]}.yml | tee ansible_run.log"
#				SHELL

			end


		end # node definition
		
	end # 1..@cfg[:node_count]

end
