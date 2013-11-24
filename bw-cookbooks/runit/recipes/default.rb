#
# Cookbook Name:: runit
# Recipe:: default
#
# Copyright 2008-2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

execute "start-runsvdir" do
    command value_for_platform(
      "debian" => { "default" => "runsvdir-start" }
    )
    action :nothing
end

execute "runit-hup-init" do
  command "telinit q"
  only_if "grep ^SV /etc/inittab"
  action :nothing
  end

package "runit" do
  action :install
  response_file "runit.seed"
  notifies value_for_platform(
    "debian" => { "4.0" => :run, "default" => :nothing  },
    "ubuntu" => {
        "default" => :nothing,
        "9.04" => :run,
        "8.10" => :run,
        "8.04" => :run }
    ), "execute[start-runsvdir]", :immediately
  notifies value_for_platform(
    "debian" => { "squeeze/sid" => :run, "default" => :nothing },
    "default" => :nothing
    ), "execute[runit-hup-init]", :immediately
end