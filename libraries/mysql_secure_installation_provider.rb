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


require 'pty'
require 'expect'

class Chef
  class Provider
    class MysqlSecureInstallation < Chef::Provider

      def load_current_resource
        @current_resource ||= Chef::Resource::MysqlSecureInstallation.new new_resource.name
        @current_resource.password new_resource.password
        @current_resource.change_password new_resource.change_password
        @current_resource.new_password new_resource.new_password
        @current_resource.remove_anonymous_users new_resource.remove_anonymous_users
        @current_resource.disallow_root_login_remotely new_resource.disallow_root_login_remotely
        @current_resource.remove_test_database new_resource.remove_test_database
        @current_resource.reload_privilege_tables_now new_resource.reload_privilege_tables_now
        return @current_resource
      end

      def action_run
        Chef::Log.debug 'About to reconfigure mysql security settings'

        PTY.spawn('mysql_secure_installation') do |ttyout, ttyin, pid|
          ttyout.expect(/Enter current password for root \(enter for none\):\s*$/) do |r|
            ttyin.printf "#{@current_resource.password}\n"
          end

          ttyout.expect(/Change the root password\? \[Y\/n\]\s*$/) do |r|
            print_yn ttyin, @current_resource.change_password
          end

          if @current_resource.change_password
            ttyout.expect(/New password:\s*$/) do |r|
              ttyin.printf "#{@current_resource.new_password}\n"
            end

            ttyout.expect(/Re-enter new password:\s*$/) do |r|
              ttyin.printf "#{@current_resource.new_password}\n"
            end
          end

          ttyout.expect(/Remove anonymous users\? \[Y\/n\]\s*$/) do |r|
            print_yn ttyin, @current_resource.remove_anonymous_users
          end

          ttyout.expect(/Disallow root login remotely\? \[Y\/n\]\s*$/) do |r|
            print_yn ttyin, @current_resource.disallow_root_login_remotely
          end

          ttyout.expect(/Remove test database and access to it\? \[Y\/n\]\s*$/) do |r|
            print_yn ttyin, @current_resource.remove_test_database
          end

          ttyout.expect(/Reload privilege tables now\? \[Y\/n\]\s*$/) do |r|
            print_yn ttyin, @current_resource.reload_privilege_tables_now
          end
        end

        Chef::Log.debug 'Reconfiguration of mysql security settings completed.'
      end

      private

      def print_yn(ttyin, value)
        ttyin.printf(value ? "y\n" : "n\n")
      end

    end
  end
end
