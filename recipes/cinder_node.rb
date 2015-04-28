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

packages = ['cinder-volume']

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
    :my_ip             => lazy { Resolv.getaddress(node[:hostname]) },
    :admin_tenant_name => node[:cinder][:admin_tenant_name],
    :admin_user        => node[:cinder][:admin_user],
    :admin_password    => node[:cinder][:admin_password],
    :backend           => node[:cinder][:backend],
    :auth_host         => node[:keystone][:host],
    :verbose           => node[:openstack][:verbose],
  })
end

file '/var/lib/cinder/cinder.sqlite' do
  action :delete
end
