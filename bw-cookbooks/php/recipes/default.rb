#
# Cookbook Name:: php
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

%w{php5-gd php5-fpm php5-cli php5-common}.each do |pkg|
  package pkg do 
    action :install
  end
end

service "php5-fpm" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

template node[:php][:fpm][:main_conf] do
  source "fpm-main.conf.erb"
  mode 0644
  notifies :restart, resources(:service => "php5-fpm"), :immediately
end

if node.recipe?("php::default") or node.recipe?("php")
  php_pool "www" do
    port "9000"
    action :add
  end
end
