actions :add, :delete
 
 
attribute :name, :kind_of => String, :name_attribute => true
attribute :user, :kind_of => String, :default => "www-data"
attribute :group, :kind_of => String, :default => "www-data"
attribute :allow, :kind_of => String, :default => "127.0.0.1"
attribute :address, :kind_of => String, :default => "127.0.0.1"
attribute :port, :kind_of => String
attribute :backlog, :kind_of => Integer, :default => -1
attribute :request_terminate_timeout, :kind_of => [Integer, String], :default => "60s"
attribute :limits, :kind_of => Hash, :default => {:core => 0, :files => 1024, :requests => 500, :children => 5, :spare_children => { :min => 1, :max => 3 } }
attribute :php_var, :kind_of => Hash, :default => {}
