Requirements
------------

### Cookbooks
   
express42 `postgresql` cookbook

express42 `php` coobook

evilmartians `nginx` coobook


### Databag

Databag ust contain following items:
* admin (with Zabbix admin password)

and two items, for postgresql database creation (see postgresql cookbook)

* databases
* users

Usage
-----

You need 3 chef run's

`run_list` = `recipe[postgresql], recipe[zabbix-server::database]`

Run!

`run_list` += `recipe[zabbix-server::server], recipe[<client>::zabbix-server]`

Run!

`run_list` += `recipe[php], recipe[nginx], recipe[zabbix-server::web]`

Run!
