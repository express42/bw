#
# Cookbook Name:: zabbix-server
# Recipe:: database
#
# Author:: LLC Express 42 (info@express42.com)
#
# Copyright (C) LLC 2013 Express 42
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

directory "/var/lib/postgresql"

partition 'zabbix-psql-db' do
  group node["zabbix-server"]["database"]["lvm_group"]
  size node["zabbix-server"]["database"]["partition_size"]
  filesystem 'ext4'
  mount_point node["zabbix-server"]["database"]["mount_point"]
  create_partition true
end

package "postgresql"

directory "/var/lib/postgresql" do
  owner "postgres"
  group "postgres"
end

listen_address = "'*'"

if node["zabbix-server"]["database"]["databag"].nil? ||
     node["zabbix-server"]["database"]["databag"].empty? ||
     !data_bag(node["zabbix-server"]["database"]["databag"]).include?('databases')

  raise "You should specify databag name  in node['zabbix-server']['database']['databag'] attibute (now: #{node['zabbix-server']['database']['databag']}) and databag should contains key 'databases'"
end

cluster_name = node['zabbix-server']['database']['cluster']
cluster_port = node['zabbix-server']['database']['port']


postgresql cluster_name do
  databag node["zabbix-server"]["database"]["databag"]
  cluster_create_options "locale" => "ru_RU.UTF-8"
  configuration(
    :version => node['zabbix-server']['database']['version'],
    :connection => {
      :listen_addresses => listen_address,
      :port => cluster_port,
      :max_connections => 300
    },
    :resources => {
      :shared_buffers => "8MB",
      :maintenance_work_mem => "128MB",
      :work_mem => "8MB"
    },
    :queries => { :effective_cache_size => "3GB" },
    :wal => { :checkpoint_completion_target => "0.9" },
    :logging => { :log_min_duration_statement => "1000" },
    :archiving => {
      :archive_mode => "on",
      :archive_command => "'exit 0'"
    },
    :standby => { :hot_standby => "on" }
  )
  hba_configuration(
    [ { :type => "host", :database => "all", :user => "all", :address => node["zabbix-server"]["database"]["network"], :method => "md5" } ]
  )
end
