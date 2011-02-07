#
# Cookbook Name:: application
# Recipe:: default
#
# Copyright 2011, Tourbuzz LLC.
#

app = node.run_state[:current_app]

###
# You really most likely don't want to run this recipe from here - let the
# default application recipe work its mojo for you.
###

## First, install any application specific packages
if app['packages']
  app['packages'].each do |pkg,ver|
    package pkg do
      action :install
      version ver if ver && ver.length > 0
    end
  end
end

## Next, install any application specific gems
if app['gems']
  app['gems'].each do |gem,ver|
    gem_package gem do
      action :install
      version ver if ver && ver.length > 0
    end
  end
end

directory app['deploy_to'] do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

directory "#{app['deploy_to']}/shared" do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

%w{ log pids system vendor_bundle }.each do |dir|
  directory "#{app['deploy_to']}/shared/#{dir}" do
    owner app['owner']
    group app['group']
    mode '0755'
    recursive true
  end
end

template "#{app['deploy_to']}/deploy-ssh-wrapper" do
  source "deploy-ssh-wrapper.erb"
  owner app['owner']
  group app['group']
  mode "0755"
  variables app.to_hash
end

if app["database_master_role"]
  dbm = nil
  # If we are the database master
  if node.run_list.roles.include?(app["database_master_role"][0])
    dbm = node
  else
  # Find the database master
    results = search(:node, "run_list:role\\[#{app["database_master_role"][0]}\\] AND app_environment:#{node[:app_environment]}", nil, 0, 1)
    rows = results[0]
    if rows.length == 1
      dbm = rows[0]
    end
  end

  # Assuming we have one...
  db_config_name = 'database'
  if dbm
  # We do this using ConfigMagic
  #   db_config_name = app["databases"][node.app_environment]["adapter"] =~ /mongodb/ ? 'mongoid' : 'database'
  #   template "#{app['deploy_to']}/shared/#{db_config_name}.yml" do
  #     source "#{db_config_name}.yml.erb"
  #     owner app["owner"]
  #     group app["group"]
  #     mode "644"
  #     variables(
  #       :host => dbm['fqdn'],
  #       :databases => app['databases']
  #     )
  #   end
  else
    Chef::Log.warn("No node with role #{app["database_master_role"][0]}, #{db_config_name}.yml not rendered!")
  end
end

## Then, deploy
deploy_revision app['id'] do
  # TODO: Mimic gitflow's determining of the current production tag
  revision app['revision'][node.app_environment]
  repository app['repository']
  user app['owner']
  group app['group']
  deploy_to app['deploy_to'][node.app_environment]
  action app['force'][node.app_environment] ? :force_deploy : :deploy
  ssh_wrapper "#{app['deploy_to']}/deploy-ssh-wrapper" if app['deploy_key']

  execute "update externals" do
    command "rake externals:init && rake externals:update"
    cwd "#{app['deploy_to']}/current"
    action :run
  end

  node.default[:apps][app['id']][node.app_environment][:run_migrations] = false
  if app['migrate'][node.app_environment] && node[:apps][app['id']][node.app_environment][:run_migrations]
    migrate true
    migration_command app['migration_command'] || "rake db:migrate"
  else
    migrate false
  end
end