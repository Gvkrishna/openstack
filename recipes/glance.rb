#
# Copyright (c) 2014 Karol Szuster
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#   KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#   WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#   OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#   WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

packages = [
  'glance',
  'python-glanceclient',
]

packages.each do |pkg|
  package pkg do
    action :install
  end
end

service 'glance-registry' do
  service_name    'glance-registry'
  restart_command 'service glance-registry restart'
  start_command   'service glance-registry start'
  action          :start
end

service 'glance-api' do
  service_name    'glance-api'
  restart_command 'service glance-api restart'
  start_command   'service glance-api start'
  action          :start
end

template '/tmp/servicedb.sql' do
  source 'servicedb.sql.erb'
  mode   00644
  owner  'root'
  group  'root'
  variables({
    :db_instance => node[:glance][:db_instance],
    :db_username => node[:glance][:db_username],
    :db_password => node[:glance][:db_password],
  })
end

execute "mysql --user=root --password='#{node[:mysql][:root_password]}' < /tmp/servicedb.sql"

keystone_user node[:glance][:admin_user] do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  password    node[:glance][:admin_password]
  email       node[:glance][:admin_email]
end

keystone_user_role 'name: glance; tenant: service, role: admin' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  name        node[:glance][:admin_user]
  tenant      node[:glance][:admin_tenant_name]
  role        'admin'
end

keystone_service 'glance' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  type        'image'
  description 'OpenStack Image Service'
end

keystone_endpoint 'keystone' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  service     'glance'
  publicurl   lazy { "http://#{node[:glance][:host]}:9292" }
  internalurl lazy { "http://#{node[:glance][:host]}:9292" }
  adminurl    lazy { "http://#{node[:glance][:host]}:9292" }
end

connection = 'mysql://%s:%s@%s/%s' % [
  node[:glance][:db_username],
  node[:glance][:db_password],
  node[:glance][:db_hostname],
  node[:glance][:db_instance],
]

template '/etc/glance/glance-registry.conf' do
  source 'glance-registry.conf.erb'
  mode   00644
  owner  'glance'
  group  'glance'
  variables({
    :connection        => connection,
    :admin_tenant_name => node[:glance][:admin_tenant_name],
    :admin_user        => node[:glance][:admin_user],
    :admin_password    => node[:glance][:admin_password],
    :auth_host         => node[:keystone][:host],
  })
  notifies :restart, 'service[glance-registry]', :immediately
end

template '/etc/glance/glance-api.conf' do
  source 'glance-api.conf.erb'
  mode   00644
  owner  'glance'
  group  'glance'
  variables({
    :connection        => connection,
    :admin_tenant_name => node[:glance][:admin_tenant_name],
    :admin_user        => node[:glance][:admin_user],
    :admin_password    => node[:glance][:admin_password],
    :auth_host         => node[:keystone][:host],
    :rabbitmq_host     => node[:rabbitmq][:host],
    :rabbitmq_userid   => node[:rabbitmq][:username],
    :rabbitmq_password => node[:rabbitmq][:password],
  })
  notifies :restart, 'service[glance-api]', :immediately
end

template '/etc/glance/glance-registry-paste.ini' do
  source 'glance-registry-paste.ini.erb'
  mode   00644
  owner  'glance'
  group  'glance'
  variables({
    :connection        => connection,
    :admin_tenant_name => node[:glance][:admin_tenant_name],
    :admin_user        => node[:glance][:admin_user],
    :admin_password    => node[:glance][:admin_password],
  })
  notifies :restart, 'service[glance-registry]', :immediately
end

template '/etc/glance/glance-api-paste.ini' do
  source 'glance-api-paste.ini.erb'
  mode   00644
  owner  'glance'
  group  'glance'
  variables({
    :admin_tenant_name => node[:glance][:admin_tenant_name],
    :admin_user        => node[:glance][:admin_user],
    :admin_password    => node[:glance][:admin_password],
  })
  notifies :restart, 'service[glance-api]', :immediately
end

file '/var/lib/glance/glance.sqlite' do
  action :delete
end

#execute 'glance db_version_control' do
#  user    'glance'
#  group   'glance'
#  command 'glance-manage db_version_control 0'
#end

execute 'glance db sync' do
  user    'glance'
  group   'glance'
  command 'glance-manage db_sync'
end
