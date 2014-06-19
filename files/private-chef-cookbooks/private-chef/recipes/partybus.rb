#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
#
# All Rights Reserved

upgrades_dir = node['private_chef']['upgrades']['dir']
upgrades_etc_dir = File.join(upgrades_dir, "etc")
upgrades_service_dir = "/opt/opscode/embedded/service/partybus"
[
  upgrades_dir,
  upgrades_etc_dir,
  upgrades_service_dir
].each do |dir_name|
  directory dir_name do
    owner node['private_chef']['user']['username']
    mode '0700'
    recursive true
  end
end

partybus_config = File.join(upgrades_etc_dir, "config.rb")

db_connection_string = "postgres:/opscode_chef"

db_service_name = "postgres"

# set the node role
node_role = node['private_chef']['role']

template partybus_config do
  source "partybus_config.rb.erb"
  owner node['private_chef']['user']['username']
  mode   "0644"
  variables(:connection_string => "postgres:/opscode_chef",
            :as_user => node['private_chef']['postgresql']['username'],
            :node_role => node_role,
            :db_service_name => db_service_name)
end

link "/opt/opscode/embedded/service/partybus/config.rb" do
  to partybus_config
end

execute "set initial migration level" do
  action :nothing
  command "cd /opt/opscode/embedded/service/partybus && ./bin/partybus init"
  subscribes :run, resources(:directory => "/var/opt/opscode"), :delayed
end
