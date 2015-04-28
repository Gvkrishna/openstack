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


default[:neutron][:db_username]                           = 'neutron'
default[:neutron][:db_password]                           = 'NEUTRON_DBPASS'
default[:neutron][:db_hostname]                           = 'controller'
default[:neutron][:db_instance]                           = 'neutron'
default[:neutron][:admin_tenant_name]                     = 'service'
default[:neutron][:admin_user]                            = 'neutron'
default[:neutron][:admin_password]                        = 'NEUTRON_PASS'
default[:neutron][:admin_email]                           = 'neutron@localhost'
default[:neutron][:host]                                  = 'controller'
default[:neutron][:neutron_metadata_proxy_shared_secret]  = 'METADATA_SECRET'
default[:neutron][:instance_tunnels_interface_ip_address] = nil
default[:neutron][:network_node]                          = true
default[:neutron][:driver]                                = 'vlan'
default[:neutron][:bridge]                                = 'br-core'
default[:neutron][:network_vlan_ranges]                   = '100:120'
