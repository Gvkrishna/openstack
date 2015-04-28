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


package 'mysql-server' do
  action :install
  response_file 'mysql.seed.erb'
end

package 'python-mysqldb' do
  action :install
end

service 'mysql' do
  service_name    'mysql'
  restart_command 'service mysql restart'
  start_command   'service mysql start'
  status_command  'service mysql status | grep -q running'
  action          [:enable, :start]
end

template '/etc/mysql/my.cnf' do
  source 'my.cnf.erb'
  owner  'root'
  group  'root'
  mode   00644
  variables({
    :bind_addr => node[:mysql][:bind_addr]
  })
  notifies :restart, 'service[mysql]', :immediately
end

execute 'mysql_install_db' do
  not_if {
    ::Dir.exists? '/var/lib/mysql/mysql' and
    ::Dir.exists? '/var/lib/mysql/performance_schema'
  }
end

mysql_secure_installation 'mysql_secure_installation' do
  password                     node[:mysql][:root_password]
  change_password              false
  new_password                 ''
  remove_anonymous_users       true
  disallow_root_login_remotely true
  remove_test_database         true
  reload_privilege_tables_now  true
end
