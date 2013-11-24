#
# Cookbook Name:: partition
# Recipe:: default
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

if node['partition']['zabbix-enabled']
  disks = `find /sys/devices/pci* -type d | grep block/[a-z,0-9,\!]*$`.split("\n")

  disks = disks.select do |disk|
    type = `cat #{disk}/device/type`.chomp.to_i
    type != 5 # dvd and so on
  end

  disks = disks.map { |disk| disk.split("\/").last.gsub("!", "\/") }

  def zbx_key(disk, field)
    "system.run[cat /proc/diskstats | grep #{disk}\\  | awk ' { print $#{field} }']"
  end

  disks.each do |disk|
    items = {
      4  => ["Reads per second, /dev/#{disk}",  :speed_per_second, zbx_key(disk, 4)],
      7  => ["Total read wait, /dev/#{disk}",   :speed_per_second, zbx_key(disk, 7)],
      8  => ["Writes per second, /dev/#{disk}", :speed_per_second, zbx_key(disk, 8)],
      11 => ["Total write wait, /dev/#{disk}",  :speed_per_second, zbx_key(disk, 11)],
      12 => ["Queue length, /dev/#{disk}",      :as_is, zbx_key(disk, 12)]
    }

    application = "Disk performance of /dev/#{disk}"

    zabbix_application application do
      items.each do |field, value|
        item_name, item_delta, key = value

        item key do
          type :active
          name item_name
          frequency 60
          delta item_delta
        end
      end

      item "r_await[#{disk}]" do
        name "Avg read wait, /dev/#{disk}"
        frequency 60
        type :calculated
        value_type :float
        formula %Q(last("#{items[7][2]}")/last("#{items[4][2]}"))
      end

      item "w_await[#{disk}]" do
        name "Avg write wait, /dev/#{disk}"
        frequency 60
        type :calculated
        value_type :float
        formula %Q(last("#{items[11][2]}")/last("#{items[8][2]}"))
      end
    end

    zabbix_graph "#{application}: io per second" do
      width 900
      height 200
      graph_items [
        {:key => items[8][2], :color => 'AA0000', :yaxisside => 0},
        {:key => items[4][2], :color => '00AA00', :yaxisside => 0}
      ]
    end

    zabbix_graph "#{application}: io latency" do
      width 900
      height 200
      graph_items [
        {:key => "w_await[#{disk}]", :color => 'AA0000', :yaxisside => 0},
        {:key => "r_await[#{disk}]", :color => '00AA00', :yaxisside => 0}
      ]
    end
  end
end
