# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Vagrantfile
# Reads node_default.yml
# Reads nodes/ for node.yml definitions
#
#   vagrant node0 up
#
require 'deep_merge'
require 'yaml'

Vagrant.configure("2") do |config|

    config.vm.synced_folder '.', '/cfg/puppet'

    begin
        node_defaults = YAML::load_stream(File.open('node_defaults.yml', 'r'))[0]
    rescue Psych::SyntaxError
        puts "check format of node_defaults.yml"
        exit
    rescue Errno::ENOENT
        puts "specify node_defaults.yml"
        exit
    end

    nodes = Array.new
    Dir.glob('nodes/*.yml').each do |cfg|
        begin
            nodes << YAML::load_stream(File.open(cfg, 'r'))
        rescue Psych::SyntaxError
            puts "error in config #{cfg}; ignoring"
        end
    end

    nodes = nodes.flatten!

    nodes.each do |node_map|
        node_map.keys.sort.each do |node_name|
            node_opts = node_map[node_name]

            config.vm.define node_name do |node|
                node_opts = node_defaults.deep_merge!(node_opts)
                fqdn = "#{node_name}.#{node_opts[:domain]}"

                node.vm.hostname = fqdn

                node.vm.box = node_opts[:box]
                node.vm.box_url = node_opts[:box_url]

                if node_opts[:private_ip]
                    node.vm.network(:private_network, :ip => node_opts[:private_ip])
                end
                if node_opts[:public_ip]
                    node.vm.network(:public_network, :bridge => node_opts[:bridge], :ip => node_opts[:public_ip])
                end

                node.vm.provider :virtualbox do |vb|
                    modifyvm_args = ['modifyvm', :id]
                    modifyvm_args << "--name" << fqdn
                    if node_opts[:memory]
                        modifyvm_args << "--memory" << node_opts[:memory]
                    end
                    # Isolate guests from host networking.
                    modifyvm_args << "--natdnsproxy1" << "on"
                    modifyvm_args << "--natdnshostresolver1" << "on"
                    modifyvm_args << "--nictype1" << "virtio"
                    vb.customize(modifyvm_args)
                end

                config.vm.provision :shell,
                    :inline => 'exec /cfg/puppet/tools/bootstrap $@',
                    :args   => ' -c ' + node_opts[:infra][:lifecycle] \
                    + ' -e ' + node_opts[:infra][:environment] \
                    + ' -g ' + node_opts[:infra][:region] \
                    + ' -i ' + node_opts[:infra][:installation] \
                    + ' -l ' + node_opts[:infra][:location] \
                    + ' -r ' + node_opts[:infra][:role]

                config.vm.provision :shell,
                    :inline => 'exec /cfg/puppet/tools/puppet-apply $@',
                    :args   => '--verbose --summarize --environment ' + node_opts[:infra][:environment]
            end
        end
    end
end
