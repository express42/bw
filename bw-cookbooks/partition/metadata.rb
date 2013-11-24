name             'partition'
maintainer       'Express 42 LLC'
maintainer_email 'info@express42.com'
license          'Apache 2.0'
description      'Configures storage (lvm or local) and add it to monitoring'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.0'
depends          'zabbix', '>= 0.1.1'
depends          'lvm', '>= 0.8.6'
