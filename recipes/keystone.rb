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
  'keystone',
  'python-keyring',
  'python-keystoneclient',
]

packages.each do |pkg|
  package pkg do
    action :install
  end
end

service 'keystone' do
  service_name    'keystone'
  restart_command 'service keystone restart'
  start_command   'service keystone start'
  action          :start
end

template '/tmp/servicedb.sql' do
  source 'servicedb.sql.erb'
  mode   00644
  owner  'root'
  group  'root'
  variables({
    :db_instance => node[:keystone][:db_instance],
    :db_username => node[:keystone][:db_username],
    :db_password => node[:keystone][:db_password],
  })
end

execute "mysql --user=root --password='#{node[:mysql][:root_password]}' < /tmp/servicedb.sql"

template '/etc/keystone/keystone.conf' do
  source 'keystone.conf.erb'
  mode   '0644'
  owner  'root'
  group  'root'
  variables({
    :admin_token => node[:keystone][:os_token],
    :log_dir     => node[:keystone][:log_dir],
    :connection  => 'mysql://%s:%s@%s/%s' % [
      node[:keystone][:db_username],
      node[:keystone][:db_password],
      node[:keystone][:db_hostname],
      node[:keystone][:db_instance],
    ],
  })
  notifies :restart, 'service[keystone]', :immediately
end

file '/var/lib/keystone/keystone.db' do
  action :delete
end

execute 'keystone db sync' do
  user    'keystone'
  group   'keystone'
  command 'keystone-manage db_sync'
end

keystone_tokenflush_log = File.join(node[:keystone][:log_dir], 'keystone-tokenflush.log')

file keystone_tokenflush_log do
  owner 'keystone'
  group 'keystone'
  mode  00600
end

bash 'add token_flush to crontab' do
  user  'keystone'
  group 'keystone'
  code <<-EOF
    {
      crontab -l | grep -v 'token_flush'
      echo "@hourly /usr/bin/keystone-manage token_flush \
        > #{keystone_tokenflush_log} 2>&1"
    } | crontab -
  EOF
end

keystone_user 'admin' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  password    node[:keystone][:admin_pass]
  email       'root@localhost'
end

keystone_role 'admin' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  action      :create
end

keystone_tenant 'admin' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  description 'Admin Tenant'
  action      :create
end

keystone_user_role 'name: admin; tenant: admin, role: _member_' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  name        'admin'
  role        '_member_'
  tenant      'admin'
end

keystone_user_role 'name: admin; tenant: admin, role: admin' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  name        'admin'
  role        'admin'
  tenant      'admin'
end

keystone_user 'demo' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  password    node[:keystone][:demo_pass]
  email       'demo@localhost'
end

keystone_tenant 'demo' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  description 'Demo Tenant'
end

keystone_user_role 'name: demo; tenant: demo, role: _member_' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  name        'demo'
  role        '_member_'
  tenant      'demo'
end

keystone_tenant 'service' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  description 'Service Tenant'
end

keystone_service 'keystone' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  type        'identity'
  description 'OpenStack Identity Service'
end

keystone_endpoint 'keystone' do
  os_endpoint node[:keystone][:os_endpoint]
  os_token    node[:keystone][:os_token]
  service     'keystone'
  publicurl   lazy { "http://#{node[:keystone][:host]}:5000/v2.0" }
  internalurl lazy { "http://#{node[:keystone][:host]}:5000/v2.0" }
  adminurl    lazy { "http://#{node[:keystone][:host]}:35357/v2.0" }
end
