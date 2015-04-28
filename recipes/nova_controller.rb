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


require 'resolv'

services = [
  'nova-api',
  'nova-cert',
  'nova-conductor',
  'nova-consoleauth',
  'nova-novncproxy',
  'nova-scheduler',
]

services.each do |name|
  package name do
    action :install
  end

  service name do
    provider   Chef::Provider::Service::Upstart
    action     :start
    subscribes :restart, "template[/etc/nova/nova.conf]", :immediately
  end
end

package 'python-novaclient' do
  action :install
end

template '/tmp/servicedb.sql' do
  source 'servicedb.sql.erb'
  mode   00644
  owner  'root'
  group  'root'
  variables({
    :db_instance => node[:nova][:db_instance],
    :db_username => node[:nova][:db_username],
    :db_password => node[:nova][:db_password],
  })
end

execute "mysql --user=root --password='#{node[:mysql][:root_password]}' < /tmp/servicedb.sql"

keystone_user node[:nova][:admin_user] do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  password    node[:nova][:admin_password]
  email       node[:nova][:admin_email]
end

keystone_user_role 'name: nova; tenant: service, role: admin' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  name        'nova'
  tenant      'service'
  role        'admin'
end

keystone_service 'nova' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  type        'compute'
  description 'OpenStack Compute'
end

keystone_endpoint 'nova' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  service     'nova'
  publicurl   lazy { "http://#{node[:nova][:host]}:8774/v2/%(tenant_id)s" }
  internalurl lazy { "http://#{node[:nova][:host]}:8774/v2/%(tenant_id)s" }
  adminurl    lazy { "http://#{node[:nova][:host]}:8774/v2/%(tenant_id)s" }
end

connection =  'mysql://%s:%s@%s/%s' % [
  node[:nova][:db_username],
  node[:nova][:db_password],
  node[:nova][:db_hostname],
  node[:nova][:db_instance],
]

template '/etc/nova/nova.conf' do
  source 'nova.conf.erb'
  mode   00640
  owner  'nova'
  group  'nova'
  variables({
    :connection                            => connection,
    :rabbitmq_host                         => node[:rabbitmq][:host],
    :rabbitmq_userid                       => node[:rabbitmq][:username],
    :rabbitmq_password                     => node[:rabbitmq][:password],
    :my_ip                                 => lazy { Resolv.getaddress(node[:hostname]) },
    :vncserver_listen                      => lazy { Resolv.getaddress(node[:hostname]) },
    :vncserver_proxyclient_address         => lazy { Resolv.getaddress(node[:hostname]) },
    :admin_tenant_name                     => node[:nova][:admin_tenant_name],
    :admin_user                            => node[:nova][:admin_user],
    :admin_password                        => node[:nova][:admin_password],
    :auth_host                             => node[:keystone][:host],
    :neutron_host                          => node[:neutron][:host],
    :neutron_admin_tenant_name             => node[:neutron][:admin_tenant_name],
    :neutron_admin_user                    => node[:neutron][:admin_user],
    :neutron_admin_password                => node[:neutron][:admin_password],
    :neutron_metadata_proxy_shared_secret  => node[:neutron][:neutron_metadata_proxy_shared_secret],
  })
end

execute 'nova db sync' do
  user    'nova'
  group   'nova'
  command 'nova-manage db sync'
end

file '/var/lib/nova/nova.sqlite' do
  action :delete
end
