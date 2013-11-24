#
# Cookbook Name:: zabbix-server
# Recipe:: server
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

db_node_ip = "127.0.0.1"

if node["zabbix-server"]["config"]["db"] && !node["zabbix-server"]["config"]["db"].empty?
  db_node_ip = node["zabbix-server"]["config"]["db"]["ip"]
end

db_node = node
db_user = "zabbix"
db_name = "zabbix"
db_pass = "zabbix"

# try search database node
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search. I will return current node or attributes value")
else
 db_node = search(:node, "role:zabbix-db AND chef_environment:#{node.chef_environment}").first
 db_node_ip = db_node[:ipaddress]
end
  
db_port = db_node["zabbix-server"]["database"]["port"]

# take user and database information from data bag

if db_node["zabbix-server"]["database"]["databag"] && !db_node["zabbix-server"]["database"]["databag"].empty?
  db_user_data = data_bag_item(db_node["zabbix-server"]["database"]["databag"], 'users')['users']
  db_user = db_user_data.keys.first
  db_pass = db_user_data[db_user]["options"]["password"]
end

apt_repository "obs-zabbix" do
    action :add
    uri "http://download.opensuse.org/repositories/home:/express42:/zabbix2/precise/ ./"
    key 'http://download.opensuse.org/repositories/home:/express42:/zabbix2/precise/Release.key'
end

package "zabbix-frontend-php" do
  response_file "zabbix-frontend-without-apache.seed"
  action [ :install, :reconfig ]
end

php_pool "zabbix-runtime" do
  address "127.0.0.1"
  port "9200"
  allow "127.0.0.1"
  backlog -1
  limits :core => 0, :files => 1024, :requests => 500, :children => 5, :spare_children => { :min => 1, :max => 3 } 
  php_var 'register_globals' => true, 
          'short_open_tag' => true, 
          'display_errors' => false, 
          'max_execution_time' => '600',
          'error_reporting' => 'E_ALL &amp; ~E_DEPRECATED', 
          'date.timezone' => 'UTC', 
          'error_log' => '/var/log/zabbix-php-error.log', 
          'memory_limit' => '128M', 
          'post_max_size' => '32M', 
          'max_input_time' => '300'
  action :add
end

template "/etc/zabbix/web/zabbix.conf.php" do
  source "zabbix.conf.php.erb"
  mode "0600"
  owner "www-data"
  group "www-data"
  variables(
    :db_host => db_node_ip,
    :db_name => db_name,
    :db_port => db_port,
    :user_name => db_user,
    :user_password => db_pass,
    :server_host => "localhost",
    :server_port => '10051')
end

nginx_site node['zabbix-server']['web']['server_name'] do
  action :enable
  template "zabbix-site.conf.erb"
  variables(
    :server_name => node['zabbix-server']['web']['server_name'],
    :fastcgi_listen => "127.0.0.1",
    :fastcgi_port => "9200"
  )
end
