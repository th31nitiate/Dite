# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # Base VM OS configuration.
  #config.vm.box = "centos/7"
  #config.vm.box = "box-cutter/ubuntu1604"
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.ssh.insert_key = false

  config.vm.provider :virtualbox do |v|
    v.memory = 2052
    v.cpus = 1
  end

  # Define four VMs with static private IP addresses.
  boxes = [
    { :name => "dev", :ip => "192.168.56.10",  :os => "centos/8"},
    { :name => "node", :ip => "192.168.56.11", :os => "centos/8"},
  ]

  # Provision each of the VMs.
  boxes.each do |opts|
    config.vm.define opts[:name] do |config|
      config.vm.hostname = opts[:name]
      config.vm.box = opts[:os]
      config.vm.box_check_update = false
      config.vm.network :private_network, ip: opts[:ip]
      #config.vm.network "forwarded_port", guest: 80, host: 8081, host_ip: "127.0.0.1"
      config.vm.hostname = "#{opts[:name]}.o3h.local"

  #sudo openssl req -newkey rsa:4096 -nodes -sha512 -x509 -days 3650 -nodes -out /etc/ssl/certs/mailserver.pem -keyout /etc/ssl/private/mailserver.pem

     #boxes.each do |values|
     #  config.vm.provision "shell", inline: "grep -q '^#{values[:ip]} ' /etc/hosts || echo '#{values[:ip]}     #{values[:name]}.o3h.lab' >> /etc/hosts"
     #end

      # Provision all the VMs using Ansible after last VM is up.
      if opts[:name] == "dev"

         #config.vm.provision "shell", inline: "sudo systemctl stop firewalld; sed -i '/127.0.1.1/d' /etc/hosts;"
        config.vm.provision "ansible" do |ansible|
          ansible.playbook = "playbook.yml"
          ansible.inventory_path = "inventory"
          ansible.verbose = "v"
          ansible.limit = "all"
        end
      end
    end
  end
end