#
# Cookbook Name:: partition
# Provider:: default
#
# Author:: LLC Express 42 (info@express42.com)
#
# Copyright (C) LLC 2012 Express 42
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

action :create do
  if new_resource.create_partition
    lvm_logical_volume new_resource.name do
      group new_resource.group
      size new_resource.size
      filesystem new_resource.filesystem
      mount_point new_resource.mount_point
    end

    if new_resource.mount_point.is_a?(Hash) and new_resource.mount_point[:location]
      mpoint = new_resource.mount_point[:location]
    else
      mpoint = new_resource.mount_point
    end

    zabbix_application "#{mpoint} filesystem" do
      item "vfs.fs.size[#{mpoint},free]" do
        type :active
        name "Free disk space on #{mpoint}"
        frequency 600
      end

      item "vfs.fs.size[#{mpoint},pfree]" do
        type :active
        name "Free disk space on #{mpoint} in %"
        frequency 600
        value_type :float
      end

      item "vfs.fs.inode[#{mpoint},free]" do
        type :active
        name "Free number of inodes on #{mpoint}"
        frequency 600
      end

      item "vfs.fs.inode[#{mpoint},pfree]" do
        type :active
        name "Free number of inodes on #{mpoint} in %"
        frequency 600
        value_type :float
      end

      item "vfs.fs.size[#{mpoint},total]" do
        type :active
        name "Total disk space on #{mpoint}"
        frequency 6000
      end

      item "vfs.fs.inode[#{mpoint},total]" do
        type :active
        name "Total number of inodes on #{mpoint}"
        frequency 6000
      end

      # Free space triggers
      {20 => :warning, 10 => :average, 5 => :high}.each do |percent, sev|
        trigger "Free space on #{mpoint}, #{percent}%" do
          expression "{#{node['fqdn']}:vfs.fs.size[#{mpoint},pfree].last(0)}<#{percent}"
          severity sev
        end
      end

      trigger "Free space on #{mpoint}, 0%" do
        expression "{#{node['fqdn']}:vfs.fs.size[#{mpoint},pfree].last(0)}=0"
        severity :disaster
      end

      # Free inodes triggers
      {20 => :warning, 10 => :average, 5 => :high}.each do |percent, sev|
        trigger "Free inodes on #{mpoint}, #{percent}%" do
          expression "{#{node['fqdn']}:vfs.fs.inode[#{mpoint},pfree].last(0)}<#{percent}"
          severity sev
        end
      end

      trigger "Free inodes on #{mpoint}, 0%" do
        expression "{#{node['fqdn']}:vfs.fs.inode[#{mpoint},pfree].last(0)}=0"
        severity :disaster
      end
    end
  end
end
