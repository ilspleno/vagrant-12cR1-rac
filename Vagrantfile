# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Variables that control node definition
NODE_NAME  = 'racnode'
NODE_COUNT = 3
CPUS       = 2
NODE_MEM   = 8192

# Where Oracle software is located
un = `uname -s`.chomp
if un.match /Linux/i
	SOFTWARE_LOC = "/storage/Software/Oracle"
else
	SOFTWARE_LOC = "d:/Software"
end
	

# Network settings
PUBLIC_PREFIX="172.16.21"
PRIVATE_PREFIX="192.168.101"
PUBLIC_OFFSET = 10
VIP_OFFSET = 20
PRIV_OFFSET = 10
SCAN_OFFSET = 30
CLUSTER_NAME = "twelvec-rac"

ANSIBLE_GROUP = "12cR1-rac"

# This isn't really creating asm diskgroups, but defines the disks that belong in each group.
# I want to use "large" disks for regular ASM but don't want the disks for OCR to be that big.
diskgroups = [
             	{ :prefix => "ocr",
                  :num    => 3,
                  :size   => 3
                },
                { :prefix => "disk",
                  :num    => 5,
                  :size   => 10
                }
             ]


## END of user variable section

# Create an /etc/hosts file that can be provisioned to each host
$hosts  = "#!/bin/bash\ncat > /etc/hosts << EOF\n127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4\n"
$hosts += "::1         localhost6 localhost6.localdomain6\n"

# Normal hostnames and vips
(1..NODE_COUNT).each do |p|
	$hosts += "#{PUBLIC_PREFIX}.#{PUBLIC_OFFSET+p}\t#{NODE_NAME}#{p}\n"
	$hosts += "#{PUBLIC_PREFIX}.#{VIP_OFFSET+p}\t#{NODE_NAME}#{p}-vip\n"
	$hosts += "#{PRIVATE_PREFIX}.#{PRIV_OFFSET+p}\t#{NODE_NAME}#{p}-priv\n"
	$hosts += "\n"
end

(1..3).each do |n|
	$hosts += "#{PUBLIC_PREFIX}.#{SCAN_OFFSET+n}\t#{CLUSTER_NAME}-scan\n"
end
$hosts += "EOF\n"

# Create an ansible inventory file based on the hosts generated
$ansible = "#!/bin/bash\ncat > /home/vagrant/#{ANSIBLE_GROUP} << EOF\n"
$ansible += "[#{ANSIBLE_GROUP}]\n"
(1..NODE_COUNT).each do |p|
	$ansible += "#{NODE_NAME}#{p}\n"
end
$ansible += "EOF\n"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

	config.vm.box = "ilspleno/centos-6-7-puppet-oracle-base"

	# Borrowing heavily from https://github.com/oravirt/vagrant-vbox-rac/blob/master/Vagrantfile for the looping in reverse creation
	
	(1..NODE_COUNT).each do |node_num|

		# Invert the order so that node 1 goes last. Once node 1 is available we can begin install
		node_num = NODE_COUNT + 1 - node_num
	
		config.vm.define "#{NODE_NAME}#{node_num}" do |node|

			node.vm.hostname = "#{NODE_NAME}#{node_num}"

			# Network config
			node.vm.network :private_network, ip: "#{PUBLIC_PREFIX}.#{PUBLIC_OFFSET+node_num}"
			node.vm.network :private_network, ip: "#{PRIVATE_PREFIX}.#{PRIV_OFFSET+node_num}"

			node.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
			node.vm.synced_folder SOFTWARE_LOC, "/software", :mount_options => ["dmode=755","fmode=755"]

			node.vm.provider :virtualbox do |vb|
				vb.customize ["modifyvm"     , :id, "--memory" , NODE_MEM]
				vb.customize ["modifyvm"     , :id, "--name"   , "#{NODE_NAME}#{node_num}"]
				vb.customize ["modifyvm"     , :id, "--cpus", CPUS]

				# Allocate disks
				
				diskport = 1
				diskpath=`VBoxManage list systemproperties | grep "Default machine folder" | awk ' { print $4; } '`.chomp
	

				diskgroups.each do |dg|

					(1..dg[:num]).each do |n|

						
						if !ENV['OS'].nil? and (ENV['OS'].match /windows/i)
							disk = diskpath + "\\#{NODE_NAME}_#{dg[:prefix]}_#{n}.vdi"
					                        else
			                                disk = diskpath + "/#{NODE_NAME}_#{dg[:prefix]}_#{n}.vdi"
                       				end

						if (node_num == NODE_COUNT) and (!File.exist?(disk.gsub /\\\\/, '\\'))
                                			# Create the disks
			                              	vb.customize ['createhd', '--filename', disk, '--size', dg[:size] * 1024, '--variant', 'Fixed']
				                        vb.customize ['modifyhd', disk, '--type', 'shareable']
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

			if (node_num == 1)
				# Extra provisioning for node 1
				node.vm.provision "shell", inline: <<-SHELL
					yum -y install ansible
					cd /home/vagrant && git clone -b 12cR1-rac https://github.com/ilspleno/ansible-oracle.git
					chown -R vagrant:vagrant /home/vagrant/ansible-oracle	
				SHELL

			end

			# Update node hostfile
			node.vm.provision "shell", inline: $hosts

			# Create ansible inventory
			node.vm.provision "shell", inline: $ansible

			if (node_num == 1)

				node.vm.provision "shell", inline: <<-SHELL
					su - vagrant -c "cd ansible-oracle && ansible-playbook -i ../#{ANSIBLE_GROUP} #{ANSIBLE_GROUP}.yml"
				SHELL

			end


		end # node definition
		
	end # 1..NODE_COUNT

end
