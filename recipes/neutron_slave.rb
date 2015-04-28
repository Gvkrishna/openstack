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
  'neutron-metadata-agent',
  'neutron-plugin-openvswitch-agent',
  'openvswitch-datapath-dkms',
  'neutron-plugin-ml2'
]

packages.each do |pkg|
  package pkg do
    action :install
  end
end

package 'neutron-plugin-openvswitch' do
  action :purge
end

services = [
  'neutron-metadata-agent',
  'neutron-plugin-openvswitch-agent',
  'openvswitch-switch',
]

services.each do |s|
  service s do
    provider Chef::Provider::Service::Upstart
    action [:enable, :start]
  end
end

template '/etc/sysctl.d/20-neutron-slave.conf' do
  source 'sysctl.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
  variables :sysctl => {
    :'net.ipv4.conf.all.rp_filter' => 0,
    :'net.ipv4.conf.default.rp_filter' => 0,
  }
end

execute 'sysctl -p /etc/sysctl.d/20-neutron-slave.conf'

template '/etc/neutron/neutron.conf' do
  action :create
  source 'neutron.conf.erb'
  owner  'neutron'
  group  'neutron'
  mode   00644
  variables({
    :admin_tenant_name    => node[:neutron][:admin_tenant_name],
    :admin_user           => node[:neutron][:admin_user],
    :admin_password       => node[:neutron][:admin_password],
    :auth_host            => node[:keystone][:host],
    :rabbitmq_host        => node[:rabbitmq][:host],
    :rabbitmq_userid      => node[:rabbitmq][:username],
    :rabbitmq_password    => node[:rabbitmq][:password],
    :driver               => node[:neutron][:driver],
    :network_vlan_ranges  => node[:neutron][:network_vlan_ranges],
    :verbose              => node[:openstack][:verbose],
  })
  notifies :restart, 'service[neutron-metadata-agent]'
  notifies :restart, 'service[neutron-plugin-openvswitch-agent]'
  notifies :restart, 'service[openvswitch-switch]'
end

template '/etc/neutron/plugins/ml2/ml2_conf.ini' do
  action :create
  source 'ml2_conf.ini.erb'
  owner  'root'
  group  'neutron'
  mode   00644
  variables ({
    :instance_tunnels_interface_ip_address => node[:neutron][:instance_tunnels_interface_ip_address],
    :driver                                => node[:neutron][:driver],
    :network_vlan_ranges                   => node[:neutron][:network_vlan_ranges],
    :bridge                                => node[:neutron][:bridge],
  })
  notifies :restart, 'service[neutron-metadata-agent]'
  notifies :restart, 'service[neutron-plugin-openvswitch-agent]'
  notifies :restart, 'service[openvswitch-switch]'
end
