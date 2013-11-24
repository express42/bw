## 0.2.3 (Jun 18, 2013)

### Minor fixes

* Cluster create options were defined as Hash and accessed as Mash.
* pg_hba.conf became faulty on long db/user names or other line fields.
* Examples in readme was badly formatted and contained small syntax issues.
* ssl was hardcoded to postgresql.conf.

## 0.2.2 (May 8, 2013)

### Minor fixes

* Check cluster_create_options hash for key before accessing it.

## 0.2.1 (Apr 14, 2013)

### Minor fixes

* Style fixes to satisfy foodcritic wishes

## 0.2.0 (Apr 14, 2013)

### Improvements

* Set LANG from cluster_create for postgresql package install(used in pg_clustercreate in debian scripts)
