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


template '/tmp/servicedb.sql' do
  source 'servicedb.sql.erb'
  mode   00644
  owner  'root'
  group  'root'
  variables({
    :db_instance => node[:neutron][:db_instance],
    :db_username => node[:neutron][:db_username],
    :db_password => node[:neutron][:db_password],
  })
end

execute "mysql --user=root --password='#{node[:mysql][:root_password]}' < /tmp/servicedb.sql"

keystone_user node[:neutron][:admin_user] do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  password    node[:neutron][:admin_password]
  email       node[:neutron][:admin_email]
end

keystone_user_role 'name: neutron; tenant: service, role: admin' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  name        node[:neutron][:admin_user]
  tenant      node[:neutron][:admin_tenant_name]
  role        'admin'
end

keystone_service 'neutron' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  type        'network'
  description 'OpenStack Networking'
end

keystone_endpoint 'keystone' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  service     'neutron'
  publicurl   lazy { "http://#{node[:neutron][:host]}:9696" }
  internalurl lazy { "http://#{node[:neutron][:host]}:9696" }
  adminurl    lazy { "http://#{node[:neutron][:host]}:9696" }
end

packages = ['neutron-server', 'neutron-plugin-ml2']

packages.each do |pkg|
  package pkg do
    action :install
  end
end

package 'neutron-plugin-openvswitch' do
  action :purge
end

service 'neutron-server' do
  provider Chef::Provider::Service::Upstart
  action   [:enable, :start]
end

connection =  'mysql://%s:%s@%s/%s' % [
  node[:neutron][:db_username],
  node[:neutron][:db_password],
  node[:neutron][:db_hostname],
  node[:neutron][:db_instance],
]

template '/etc/neutron/plugins/ml2/ml2_conf.ini' do
  action :create
  source 'ml2_conf.ini.erb'
  owner  'root'
  group  'root'
  mode   00644
  variables ({
    :driver              => node[:neutron][:driver],
    :network_vlan_ranges => node[:neutron][:network_vlan_ranges],
    :bridge              => node[:neutron][:bridge],
  })
  notifies :restart, 'service[nova-api]', :immediately
  notifies :restart, 'service[nova-scheduler]', :immediately
  notifies :restart, 'service[nova-conductor]', :immediately
  notifies :restart, 'service[neutron-server]', :immediately
end

template '/etc/neutron/neutron.conf' do
  action :create
  source 'neutron.conf.erb'
  owner  'neutron'
  group  'neutron'
  mode   00644
  variables({
    :connection           => connection,
    :admin_tenant_name    => node[:neutron][:admin_tenant_name],
    :admin_user           => node[:neutron][:admin_user],
    :admin_password       => node[:neutron][:admin_password],
    :host                 => node[:neutron][:host],
    :auth_host            => node[:keystone][:host],
    :rabbitmq_host        => node[:rabbitmq][:host],
    :rabbitmq_userid      => node[:rabbitmq][:username],
    :rabbitmq_password    => node[:rabbitmq][:password],
    :nova_host            => node[:nova][:host],
    :nova_admin_user      => node[:nova][:admin_user],
    :nova_admin_tenant_id => lazy {
      client = KeystoneClient.new(node[:keystone][:os_token], node[:keystone][:os_endpoint])
      client.get_tenant_id_by_name!(node[:nova][:admin_tenant_name])
    },
    :nova_admin_password  => node[:nova][:admin_password],
    :verbose              => node[:openstack][:verbose],
    :driver               => node[:neutron][:driver],
    :network_vlan_ranges  => node[:neutron][:network_vlan_ranges],
  })
  notifies :restart, 'service[nova-api]', :immediately
  notifies :restart, 'service[nova-scheduler]', :immediately
  notifies :restart, 'service[nova-conductor]', :immediately
  notifies :restart, 'service[neutron-server]', :immediately
end
