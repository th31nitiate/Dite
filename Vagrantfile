# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|
  config.vm.synced_folder '.', '/srv/hosts', disabled: false
  config.ssh.insert_key = false

  config.vm.provider :virtualbox do |v|
    v.memory = 1024
    v.cpus = 1
  end

  # Define four VMs with static private IP addresses.
  boxes = [
    { :name => "acreage", :ip => "192.168.56.10",  :os => "bento/centos-7"},
    { :name => "facet", :ip => "192.168.56.11", :os => "bento/centos-7"},
  ]

  # Provision each of the VMs.
  boxes.each do |opts|
    config.vm.define opts[:name] do |config|
      config.vm.hostname = opts[:name]
      config.vm.box = opts[:os]
      config.vm.box_check_update = false
      config.vm.network :private_network, ip: opts[:ip]
      config.vm.hostname = "#{opts[:name]}.dite.local"
      config.vm.provision "shell", path: "build.sh"
    end

  end
end
