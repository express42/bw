#!/usr/bin/env ruby
#Dir.chdir File.join(__FILE__, "../..")
#gem 'chef', '11.4.4'
require 'openssl'

unless ENV['EDITOR']
  puts "No EDITOR found. Try:"
  puts "export EDITOR=vim"
  exit 1
end

unless ARGV.count == 1
  puts "usage: #{$0} <filename>"
  exit 1
end

require 'chef/encrypted_data_bag_item'
require 'json'
require 'tempfile'

Chef::Config[:data_bag_encrypt_version] = 2

encrypted_path = ARGV[0]

data_bag_key_path = File.join(Dir.pwd, ".chef/encrypted_data_bag_secret")
unless File.exists? data_bag_key_path
  puts "Get the data_bag_key and put it in #{data_bag_key_path}."
  exit 1
end

secret = Chef::EncryptedDataBagItem.load_secret(data_bag_key_path)

decrypted_file = Tempfile.new Digest::SHA256.hexdigest(encrypted_path)
at_exit { decrypted_file.delete }

if File.exists? encrypted_path
  encrypted_data = JSON.parse(File.read(encrypted_path))
  plain_data = Chef::EncryptedDataBagItem.new(encrypted_data, secret).to_hash

  decrypted_file.puts JSON.pretty_generate(plain_data)
else
  puts "Creating new file #{File.join(Dir.pwd, encrypted_path)}"
end

decrypted_file.close

system "#{ENV['EDITOR']} #{decrypted_file.path}"

plain_data = JSON.parse(File.read(decrypted_file.path))
encrypted_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(plain_data, secret)

File.write encrypted_path, JSON.pretty_generate(encrypted_data)
