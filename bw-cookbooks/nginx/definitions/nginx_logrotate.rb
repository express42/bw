#
# Cookbook Name:: nginx
# Definition:: nginx_logrotate
#
# Author:: Kirill Kouznetsov
#
# Copyright 2012, Kirill Kouznetsov.
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

define :nginx_logrotate do
  nginx_l_t = resources(:nginx_logrotate_template => "nginx")
  params.each do |param,value|
    next if param == :name
    nginx_l_t.send(param, value)
  end
end

# vim: ts=2 sts=2 sw=2 sta et
