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

# default values

require 'digest/md5'

check_db_flag = false

db_node_ip = "127.0.0.1"

admin_user_pass = "zabbix"

if node["zabbix-server"]["config"]["db"] && !node["zabbix-server"]["config"]["db"].empty?
  db_node_ip = node["zabbix-server"]["config"]["db"]["ip"]
end

db_node = node
db_name = "zabbix"

# try search database node
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search. I will return current node or attributes value")
else
 db_node = search(:node, "role:zabbix-db AND chef_environment:#{node.chef_environment}").first
 db_node_ip = db_node[:ipaddress]
end

db_node_port = db_node["zabbix-server"]["database"]["port"]

# take user and database information from data bag

if db_node["zabbix-server"]["database"]["databag"].nil? ||
     db_node["zabbix-server"]["database"]["databag"].empty? ||
     data_bag(db_node["zabbix-server"]["database"]["databag"]).empty?
  raise "You should specify databag name for zabbix db user in node['zabbix-server']['database']['databag'] attibute (now: #{node['zabbix-server']['database']['databag']}) and databag should exists"
end

db_user_data = data_bag_item(db_node["zabbix-server"]["database"]["databag"], 'users')['users']
db_user = db_user_data.keys.first
db_pass = db_user_data[db_user]["options"]["password"]

# get Admin password from databag

begin
  admin_user_pass = data_bag_item(node['zabbix-server']['credentials']['databag'], 'admin')['pass']
rescue
  Chef::Log.info("Using default password for user Admin ... (pass: zabbix)")
end

admin_user_pass_md5 = Digest::MD5.hexdigest(admin_user_pass)

# prepare db configuration for config file

db_config = {
  :db => {
    :DBName => db_name,
    :DBPassword => db_pass,
    :DBUser => db_user,
    :DBHost => db_node_ip,
    :DBPort => db_node_port
  }
}

db_connect_string = "psql -q -t  -h #{db_node_ip} -p #{db_node_port} -U #{db_user} -d #{db_name}"

Chef::Log.info("Connect to postgres with connection string #{db_connect_string}")

package "postgresql-client" do
  action :install
end

apt_repository "obs-zabbix" do
    action :add
    uri "http://download.opensuse.org/repositories/home:/express42:/zabbix2/precise/ ./"
    key 'http://download.opensuse.org/repositories/home:/express42:/zabbix2/precise/Release.key'
end

apt_repository "obs-main" do
    action :add
    uri "http://download.opensuse.org/repositories/home:/express42:/web/precise/ ./"
    key 'http://download.opensuse.org/repositories/home:/express42:/web/precise/Release.key'
end

package "zabbix-server-pgsql" do
  response_file "zabbix-server-withoutdb.seed"
  action [ :install, :reconfig ]
end

ruby_block "checking database persistance" do
  block do
    # check connect to database

    psql_output = IO.popen("PGPASSWORD=#{db_pass} #{db_connect_string} -c 'SELECT 1'")
    psql_output_res = psql_output.readlines
    psql_output.close

    if $?.exitstatus != 0 || psql_output_res[0].to_i != 1
       Chef::Log.error("Couldn't connect to database on host #{db_node[:fqdn]}, please check database server configuration")
       check_db_flag = false
    else
      # check that database for zabbix exists, otherwise make database provisioning

      check_db_exist = IO.popen("PGPASSWORD=#{db_pass} #{db_connect_string} -c \"select count(*) from users where alias='Admin'\"")
      check_db_exist_res = check_db_exist.readlines
      check_db_exist.close
      check_db_flag =  !( $?.exitstatus == 0 && check_db_exist_res[0].to_i == 1 )
      Chef::Log.info("Zabbix database has been already provisioned, skeep provisioning step ...") if not check_db_flag
    end
  end
  action :create
end

execute "provisioning zabbix database" do
  command "#{db_connect_string} -f /usr/share/zabbix-server-pgsql/schema.sql; \
           #{db_connect_string} -f /usr/share/zabbix-server-pgsql/data.sql;   \
           #{db_connect_string} -f /usr/share/zabbix-server-pgsql/images.sql; "
  environment({'PGPASSWORD' => db_pass})
  only_if { check_db_flag }
  action :run
end

ruby_block "set password for web user Admin" do
  block do
    if !check_db_flag
      getdb_admin_user_pass_query = IO.popen("PGPASSWORD=#{db_pass} #{db_connect_string} -c \"select passwd from users where alias='Admin'\"")
      getdb_admin_user_pass = getdb_admin_user_pass_query.readlines[0].to_s.gsub( /\s+/, "")
      getdb_admin_user_pass_query.close

      if getdb_admin_user_pass != admin_user_pass_md5 
        set_admin_pass_query = IO.popen("PGPASSWORD=#{db_pass} #{db_connect_string} -c \"update users set passwd='#{admin_user_pass_md5}' where alias = 'Admin';\"")
        set_admin_pass_query_res = set_admin_pass_query.readlines
        set_admin_pass_query.close
      end

      Chef::Log.info("Password for web user Admin has been successfully updated.") if set_admin_pass_query_res
    end
  end
end

service node["zabbix-server"]["service"] do
  supports :restart => true, :status => true, :reload => true
  action [ :enable ]
end

template "/etc/zabbix/zabbix_server.conf" do
  source "zabbix-server.conf.erb"
  owner "root"
  group "root"
  mode "640"
  variables(node["zabbix-server"]["config"].to_hash.merge(db_config))
  notifies :restart, "service[#{node["zabbix-server"]["service"]}", :immediately
end
