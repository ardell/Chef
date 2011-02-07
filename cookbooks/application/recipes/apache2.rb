#
# Cookbook Name:: application
# Recipe:: default
#
# Copyright 2011, Tourbuzz LLC.
#

app = node.run_state[:current_app] 

include_recipe "apache2"
