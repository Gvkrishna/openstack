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


require 'chef/resource'

class Chef
  class Resource
    class MysqlSecureInstallation < Chef::Resource

      def initialize(name, run_context=nil)
        super
        @resource_name = :mysql_secure_installation
        @provider = Chef::Provider::MysqlSecureInstallation
        @allowed_actions = [:run]

        @action = :run

        @change_password = false
        @remove_anonymous_users = true
        @disallow_root_login_remotely = true
        @remove_test_database = true
        @reload_privilege_tables_now = true
      end

      def password(arg=nil)
        set_or_return :password, arg, :kind_of => String
      end

      def change_password(arg=nil)
        set_or_return :change_password, arg,
                      :kind_of => [TrueClass, FalseClass]
      end

      def new_password(arg=nil)
        set_or_return :new_password, arg, :kind_of => String
      end

      def remove_anonymous_users(arg=nil)
        set_or_return :remove_anonymous_users, arg,
                      :kind_of => [TrueClass, FalseClass]
      end

      def disallow_root_login_remotely(arg=nil)
        set_or_return :disallow_root_login_remotely, arg,
                      :kind_of => [TrueClass, FalseClass]
      end

      def remove_test_database(arg=nil)
        set_or_return :remove_test_database, arg,
                      :kind_of => [TrueClass, FalseClass]
      end

      def reload_privilege_tables_now(arg=nil)
        set_or_return :reload_privilege_tables_now, arg,
                      :kind_of => [TrueClass, FalseClass]
      end

    end
  end
end
