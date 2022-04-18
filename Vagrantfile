Vagrant.configure("2") do |config|
  config.vm.box = "gbailey/amzn2"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.provision "shell", path: "./provisioning.sh"
end
