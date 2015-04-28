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


packages = ['cinder-api', 'cinder-scheduler']

packages.each do |pkg|
  package pkg do
    action :install
  end

  service pkg do
    provider   Chef::Provider::Service::Upstart
    action     [:enable, :start]
    subscribes :restart, "template[/etc/cinder/cinder.conf]", :immediately
  end
end

connection = 'mysql://%s:%s@%s/%s' % [
  node[:cinder][:db_username],
  node[:cinder][:db_password],
  node[:cinder][:db_hostname],
  node[:cinder][:db_instance],
]

template '/etc/cinder/cinder.conf' do
  source 'cinder.conf.erb'
  mode   00644
  owner  'cinder'
  group  'cinder'
  variables({
    :connection        => connection,
    :rabbitmq_host     => node[:rabbitmq][:host],
    :rabbitmq_userid   => node[:rabbitmq][:username],
    :rabbitmq_password => node[:rabbitmq][:password],
    :admin_tenant_name => node[:cinder][:admin_tenant_name],
    :admin_user        => node[:cinder][:admin_user],
    :admin_password    => node[:cinder][:admin_password],
    :backend           => node[:cinder][:backend],
    :auth_host         => node[:keystone][:host],
    :verbose           => node[:openstack][:verbose],
  })
end

template '/tmp/servicedb.sql' do
  source 'servicedb.sql.erb'
  mode   00644
  owner  'root'
  group  'root'
  variables({
    :db_instance => node[:cinder][:db_instance],
    :db_username => node[:cinder][:db_username],
    :db_password => node[:cinder][:db_password],
  })
end

execute "mysql --user=root --password='#{node[:mysql][:root_password]}' < /tmp/servicedb.sql"

execute 'cinder db sync' do
  user    'cinder'
  group   'cinder'
  command 'cinder-manage db sync'
end

keystone_user node[:cinder][:admin_user] do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  password    node[:cinder][:admin_password]
  email       node[:cinder][:admin_email]
end

keystone_user_role 'name: cinder; tenant: service, role: admin' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  name        node[:cinder][:admin_user]
  tenant      node[:cinder][:admin_tenant_name]
  role        'admin'
end

keystone_service 'cinder' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  type        'volume'
  description 'OpenStack Block Storage'
end

keystone_endpoint 'keystone' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  service     'cinder'
  publicurl   lazy { "http://#{node[:cinder][:host]}:8776/v1/%(tenant_id)s" }
  internalurl lazy { "http://#{node[:cinder][:host]}:8776/v1/%(tenant_id)s" }
  adminurl    lazy { "http://#{node[:cinder][:host]}:8776/v1/%(tenant_id)s" }
end

keystone_service 'cinderv2' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  type        'volumev2'
  description 'OpenStack Block Storage v2'
end

keystone_endpoint 'keystonev2' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  service     'cinderv2'
  publicurl   lazy { "http://#{node[:cinder][:host]}:8776/v2/%(tenant_id)s" }
  internalurl lazy { "http://#{node[:cinder][:host]}:8776/v2/%(tenant_id)s" }
  adminurl    lazy { "http://#{node[:cinder][:host]}:8776/v2/%(tenant_id)s" }
end

file '/var/lib/cinder/cinder.sqlite' do
  action :delete
end
