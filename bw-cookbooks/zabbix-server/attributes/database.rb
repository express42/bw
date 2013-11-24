default["zabbix-server"]["database"] = {
  :lvm_group => "shared",
  :partition_size => "10G"
}

default["zabbix-server"]["database"]["databag"] = "zabbix"
default["zabbix-server"]["database"]["network"] = "172.16.0.0/16"

default["zabbix-server"]["database"]["version"] = "9.1"
default["zabbix-server"]["database"]["cluster"] = "main"
default["zabbix-server"]["database"]["port"] = "5432"
default["zabbix-server"]["database"]["mount_point"] = "/var/lib/postgresql"


