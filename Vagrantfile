Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty32"
  config.vm.synced_folder ".", "/var/www/html/", :owner=>"www-data",:group=>"www-data"
  config.vm.provision :shell, :path => "vagrant.sh"
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
  end
    
  # Port forward guest 80 to host 3000
  config.vm.network :forwarded_port, guest: 80, host: 3000, auto_correct: true
  config.vm.network :forwarded_port, guest: 9200, host: 9200, auto_correct: true  
end
