# Basic Chef Setup

## Installation

1. Install Ruby (we recommend rvm with Ruby 1.8.7-p173)
2. `gem install bundler`
3. `bundle install` (installs chef, knife, and other tools)
4. `cp .chef/knife.rb.sample .chef/knife.rb` and customize

## To add a cookbook

This command will import a cookbook from the "blessed" Opscode cookbooks at http://cookbooks.opscode.com.

    knife cookbook site vendor COOKBOOK_NAME
    knife cookbook upload COOKBOOK_NAME

## To add a role

    knife role from file ROLE_NAME.rb

## To add a data_bag

    knife data bag create DATA_BAG_NAME
    knife data bag from file DIR DATA_BAG_NAME.json

## To boot a server

    knife ec2 server create 'role[staging]' 'role[base]' 'role[app]' 'role[database_master]' --ssh-key ec2-keypair --identity-file .chef/ec2-keypair.pem --ssh-user ubuntu --groups default --image ami-88f504e1 --flavor m1.small -Z us-east-1a

### Flags:
+ `-f` m1.small is the size of the instance we want
+ `-i` ami-480df921 says use the stock ubuntu ebs volume instance
+ `-S` ec2-keypair is the name of the keypair on aws
+ `-x` ubuntu says connect via ssh with the "ubuntu" username (instead of default=root)
+ `-I` ~/Documents/workspace/chef/.chef/ec2-keypair.pem says use the key at this location
+ `-Z` us-east-1a Amazon doesn't have capacity of m1.small servers at us-east-1b (which is our default data center), so we use this one instead
+ `-N` [name] is required because otherwise amazon gives chef a _local_.internal hostname that doesn't work. If we reference it by name it works

## To update your server

    knife ssh 'role:app' 'sudo chef-client' -a ec2.public_hostname --ssh-user ubuntu
