# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.ssh.insert_key = false

  config.vm.provider :virtualbox do |v|
    v.memory = 2052
    v.cpus = 1
  end

  # Define four VMs with static private IP addresses.
  boxes = [
    { :name => "acreage", :ip => "192.168.56.10",  :os => "centos/8"},
    { :name => "facet", :ip => "192.168.56.11", :os => "centos/8"},
  ]

  # Provision each of the VMs.
  boxes.each do |opts|
    config.vm.define opts[:name] do |config|
      config.vm.hostname = opts[:name]
      config.vm.box = opts[:os]
      config.vm.box_check_update = false
      config.vm.network :private_network, ip: opts[:ip]
      #config.vm.network "forwarded_port", guest: 80, host: 8081, host_ip: "127.0.0.1"
      config.vm.hostname = "#{opts[:name]}.dite.local"

    end
  end


  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.inventory_path = "inventory"
    ansible.verbose = "v"
    ansible.limit = "all"
  end
end