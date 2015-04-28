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


default[:nova][:db_username]         = 'nova'
default[:nova][:db_password]         = 'NOVA_DBPASS'
default[:nova][:db_hostname]         = 'controller'
default[:nova][:db_instance]         = 'nova'
default[:nova][:admin_tenant_name]   = 'service'
default[:nova][:admin_user]          = 'nova'
default[:nova][:admin_password]      = 'NOVA_PASS'
default[:nova][:admin_email]         = 'nova@localhost'
default[:nova][:host]                = 'controller'
default[:nova][:vnc_enabled]         = false
default[:nova][:novncproxy_base_url] = 'http://controller:6080/vnc_auto.html'
default[:nova][:glance_host]         = 'controller'
default[:nova][:compute_driver]      = 'libvirt.LibvirtDriver'
default[:nova][:virt_type]           = 'kvm'
