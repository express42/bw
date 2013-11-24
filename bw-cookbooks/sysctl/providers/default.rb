#
# Cookbook Name:: sysctl
# Provider:: default
#
# Author:: LLC Express 42 (info@express42.com)
#
# Copyright (C) 2012-2013 LLC Express 42
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
#

action :generate do
  keys = {}
  resources = run_context.resource_collection.all_resources.select do |resource|
    resource.resource_name == new_resource.resource_name and resource.attrs != 'sysctl'
  end

  resources.each do |res|
    res.attrs.each do |k, v|
      key = k.to_s
      if keys.has_key?(key)
        raise "Two keys with different values are not allowed" if keys[key] != v
        next
      end
      keys[key] = v
    end
  end

  template "/etc/sysctl.conf" do
    source "sysctl.conf.erb"
    cookbook "sysctl"
    owner "root"
    group "root"
    mode 0644
    variables :attrs => keys
    notifies :restart, "service[procps]", :immediately
  end
end