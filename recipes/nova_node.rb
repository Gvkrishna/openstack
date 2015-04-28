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

package 'nova-compute-kvm' do
  action :install
end

service 'nova-compute' do
  start_command   'service nova-compute start'
  stop_command    'service nova-compute stop'
  restart_command 'service nova-compute restart'
  action :nothing
end

template '/etc/nova/nova.conf' do
  source 'nova.conf.erb'
  mode   00640
  owner  'nova'
  group  'nova'
  variables({
    :rabbitmq_host                 => node[:rabbitmq][:host],
    :rabbitmq_userid               => node[:rabbitmq][:username],
    :rabbitmq_password             => node[:rabbitmq][:password],
    :my_ip                         => lazy { Resolv.getaddress(node[:hostname]) },
    :vncserver_listen              => lazy { '0.0.0.0' },
    :vncserver_proxyclient_address => lazy { Resolv.getaddress(node[:hostname]) },
    :admin_tenant_name             => node[:nova][:admin_tenant_name],
    :admin_user                    => node[:nova][:admin_user],
    :admin_password                => node[:nova][:admin_password],
    :auth_host                     => node[:keystone][:host],
    :vnc_enabled                   => true,
    :novncproxy_base_url           => node[:nova][:novncproxy_base_url],
    :glance_host                   => node[:nova][:glance_host],
    :neutron_host                  => node[:neutron][:host],
    :neutron_admin_tenant_name     => node[:neutron][:admin_tenant_name],
    :neutron_admin_user            => node[:neutron][:admin_user],
    :neutron_admin_password        => node[:neutron][:admin_password],
  })
  notifies :restart, "service[nova-compute]", :immediately
end

template '/etc/nova/nova-compute.conf' do
  source 'nova-compute.conf.erb'
  mode   00640
  owner  'nova'
  group  'nova'
  variables({
    :compute_driver => node[:nova][:compute_driver],
    :virt_type      => node[:nova][:virt_type],
  })
  notifies :restart, "service[nova-compute]", :immediately
end

file '/var/lib/nova/nova.sqlite' do
  action :delete
end
