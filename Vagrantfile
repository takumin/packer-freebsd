# vim: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box      = 'freebsd64-101r'
  config.vm.hostname = 'vagrant'
  config.vm.network :private_network, ip: '10.0.0.10'
  config.vm.network :forwarded_port,  guest: 80,  host: 8080
  config.vm.network :forwarded_port,  guest: 443, host: 4443
  config.ssh.forward_agent = true

  config.vm.synced_folder ".", "/usr/local/vagrant", type: "rsync",
    rsync__args: ["--verbose", "--archive", "--delete", "-zz"],
    rsync__exclude: [".gitignore", ".git/", ".vagrant/"]

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
    vb.customize ["modifyvm", :id, "--cpus",     "2"]
    vb.customize ["modifyvm", :id, "--memory",   "2048"]
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
    vb.customize ["modifyvm", :id, "--audio",    "none"]
  end
end
