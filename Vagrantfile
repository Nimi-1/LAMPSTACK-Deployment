# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-20.04"
  
  config.vm.define "master" do |master|
    master.vm.network "private_network", ip: "192.168.56.8"
    master.vm.hostname = "master"
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "1"
    end
    master.vm.provision "shell", path: "./laravel.sh"
  end  

  config.vm.define "slave" do |slave|
    slave.vm.network "private_network", ip: "192.168.56.9"
    slave.vm.hostname = "slave"
    slave.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "1"
    end
  end
end