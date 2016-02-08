# -*- mode: ruby -*-
# vi: set ft=ruby :

# Bring in some code to verify plugins and create asm disks
require_relative '../vagrant-libs/plugin_manager.rb'
require_relative '../vagrant-libs/disk_manager.rb'

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

disk_layout = { :project => '12cR1-rac',
                :shareable => true,
		:create => true,
                :groups => [
                            { :prefix => "ocr",
                              :num    => 3,
                              :size   => 3     },
                            { :prefix => "disk",
                              :num    => 5,
                              :size   => 10
                            }
                           ]
              }


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
		
#	config.hostmanager.enabled = true
#	config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
#		if vm.id
#			`VBoxManage guestproperty get #{vm.id} "/VirtualBox/GuestInfo/Net/1/V4/IP"`.split()[1]
#		end
#	end

	# Create hard drives to be shared
	config.vm.provider :virtualbox do |vb|
 		# Call the function in disk_manager.rb to provision disks for ASM
                create_asm_disks(vb, disk_layout)
	end

	# Set create false so individual nodes just attach to it
	disk_layout[:create] = false
                       

	config.vm.define "cenoradb12r21" , primary: true do |oradb|
 		oradb.vm.box = "ilspleno/centos-6-7-puppet-oracle-base"
 		oradb.vm.hostname = 'cenoradb12r21'

		#oradb.vm.network :private_network, type: "dhcp"
		#oradb.vm.network :private_network, type: "dhcp"
		oradb.vm.network "private_network", ip: "10.0.10.11", virtualbox__intnet: "Public"
		oradb.vm.network "private_network", ip: "10.0.11.11", virtualbox__intnet: "Private"


		oradb.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
                oradb.vm.synced_folder "d:/Software", "/software", :mount_options => ["dmode=755","fmode=755"]


		oradb.vm.provider :virtualbox do |vb|
			vb.customize ["modifyvm"     , :id, "--memory" , "4096"]
			vb.customize ["modifyvm"     , :id, "--name"   , "cenoradb12r21"]

			# Call the function in disk_manager.rb to provision disks for ASM
			create_asm_disks(vb, disk_layout)

		end


		oradb.vm.network :forwarded_port, guest: 22, host: 2200, auto_correct: true
		oradb.vm.network :forwarded_port, guest: 1521, host: 1521
		config.vm.provision "shell", inline: <<-SHELL
			cp -v /vagrant/scripts/id_rsa* /home/vagrant/.ssh
			chown vagrant:vagrant /home/vagrant/.ssh/id_rsa
			cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
			chmod 600 /home/vagrant/.ssh/id_rsa*
			yum -y install ansible
			cd /home/vagrant && git clone https://github.com/ilspleno/ansible-oracle.git
			chown -R vagrant /home/vagrant/ansible-oracle	
			cp -v /vagrant/files/hosts /etc/hosts
		SHELL


	end

	config.vm.define "cenoradb12r22" , primary: true do |oradb|
 		oradb.vm.box = "ilspleno/centos-6-7-puppet-oracle-base"
 		oradb.vm.hostname = 'cenoradb12r22'

		#oradb.vm.network :private_network, type: "dhcp"
		oradb.vm.network "private_network", ip: "10.0.10.12", virtualbox__intnet: "Public"
		oradb.vm.network "private_network", ip: "10.0.11.12", virtualbox__intnet: "Private"


		oradb.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]

		oradb.vm.provider :virtualbox do |vb|
			vb.customize ["modifyvm"     , :id, "--memory" , "4096"]
			vb.customize ["modifyvm"     , :id, "--name"   , "cenoradb12r22"]

			# Call the function in disk_manager.rb to provision disks for ASM
			create_asm_disks(vb, disk_layout)

		end


		oradb.vm.network :forwarded_port, guest: 22, host: 2200, auto_correct: true
		oradb.vm.network :forwarded_port, guest: 1521, host: 1522

		config.vm.provision "shell", inline: <<-SHELL
			cp -v /vagrant/scripts/id_rsa* /home/vagrant/.ssh
			chown vagrant:vagrant /home/vagrant/.ssh/id_rsa
			cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
			chmod 600 /home/vagrant/.ssh/id_rsa*
			cp -v /vagrant/files/hosts /etc/hosts
		SHELL

	end

end
