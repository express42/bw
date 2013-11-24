Sysctl Cookbook
======================

Configure sysctl parameters. Contains a LWRP for creating sysctl.

Requirements
------------

Tested only on Ubuntu 12.04, but should works on Debian too.

Usage
-----

## systcl default recipe

Just include `sysctl` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[sysctl]"
  ]
}
```

It deletes all files in /etc/sysctl.d/* and generate /etc/sysctl.conf by calling LWRP.

## LWRP zabbix::default

### Actions
<table>
  <tr>
    <th>Action</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>create</td>
    <td>Default action. Create new sysctl parameter</td>
  </tr>
  <tr>
    <td>generate</td>
    <td>Generate /etc/sysctl.conf file. Should not call manually</td>
  </tr>
</table>

### Examples
```ruby
sysctl(
  'vm.overcommit_memory' => 0,
  'net.ipv4.tcp_rmem' => '4096 87380 16777216',
  'kernel.shmmax' => 68719476736
)
```

Contributing
------------
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Author:: Ivan Evtuhovich <ivan@express42.com>
Author:: Alexander Titov <alex@express42.com>

Copyright 2012-2013, Express 42, LLC

