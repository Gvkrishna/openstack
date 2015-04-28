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


include_recipe 'openstack::neutron_slave'

packages = [
  'neutron-l3-agent',
  'neutron-dhcp-agent',
]

services = [
  'neutron-l3-agent',
  'neutron-dhcp-agent',
]

packages.each do |pkg|
  package pkg do
    action :install
  end
end

services.each do |s|
  service s do
    provider Chef::Provider::Service::Upstart
    action [:enable, :start]
  end
end

template '/etc/sysctl.d/20-neutron-master.conf' do
  source 'sysctl.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
  variables :sysctl => { :'net.ipv4.ip_forward' => 1 }
end

execute 'sysctl -p /etc/sysctl.d/20-neutron-master.conf'

template '/etc/neutron/l3_agent.ini' do
  action :create
  source 'l3_agent.ini.erb'
  owner 'root'
  group 'neutron'
  mode  00644
  variables :verbose => node[:openstack][:verbose]
  notifies :restart, 'service[neutron-l3-agent]'
  notifies :restart, 'service[neutron-metadata-agent]'
  notifies :restart, 'service[neutron-plugin-openvswitch-agent]'
  notifies :restart, 'service[neutron-dhcp-agent]'
end

template '/etc/neutron/dhcp_agent.ini' do
  action :create
  source 'dhcp_agent.ini.erb'
  owner 'root'
  group 'neutron'
  mode  00644
  variables :verbose => node[:openstack][:verbose]
  notifies :restart, 'service[neutron-l3-agent]'
  notifies :restart, 'service[neutron-metadata-agent]'
  notifies :restart, 'service[neutron-plugin-openvswitch-agent]'
  notifies :restart, 'service[neutron-dhcp-agent]'
end

template '/etc/neutron/dnsmasq-neutron.conf' do
  action :create
  source 'dnsmasq-neutron.conf.erb'
  owner 'root'
  group 'neutron'
  mode  00644
  notifies :restart, 'service[neutron-l3-agent]'
  notifies :restart, 'service[neutron-metadata-agent]'
  notifies :restart, 'service[neutron-plugin-openvswitch-agent]'
  notifies :restart, 'service[neutron-dhcp-agent]'
end

template '/etc/neutron/metadata_agent.ini' do
  action :create
  source 'metadata_agent.ini.erb'
  owner 'root'
  group 'neutron'
  mode  00644
  variables ({
    :admin_tenant_name                    => node[:neutron][:admin_tenant_name],
    :admin_user                           => node[:neutron][:admin_user],
    :admin_password                       => node[:neutron][:admin_password],
    :auth_host                            => node[:keystone][:host],
    :nova_host                            => node[:nova][:host],
    :neutron_metadata_proxy_shared_secret => node[:neutron][:neutron_metadata_proxy_shared_secret],
    :verbose                              => node[:openstack][:verbose],
  })
  notifies :restart, 'service[neutron-l3-agent]'
  notifies :restart, 'service[neutron-metadata-agent]'
  notifies :restart, 'service[neutron-plugin-openvswitch-agent]'
  notifies :restart, 'service[neutron-dhcp-agent]'
end
