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
    class KeystoneTenant < Chef::Resource

      def initialize(name, run_context=nil)
        super
        @resource_name = :keystone_tenant
        @provider = Chef::Provider::KeystoneTenant
        @allowed_actions = [:create]

        @action = :create
        @enabled = true
      end

      def os_token(arg=nil)
        set_or_return(:os_token, arg, :kind_of => String)
      end

      def os_endpoint(arg=nil)
        set_or_return(:os_endpoint, arg, :kind_of => String)
      end

      def description(arg=nil)
        set_or_return(:description, arg, :kind_of => String)
      end

      def enabled(arg=nil)
        set_or_return(:enabled, arg, :kind_of => [TrueClass, FalseClass])
      end
    end

    class KeystoneRole < Chef::Resource

      def initialize(name, run_context=nil)
        super
        @resource_name = :keystone_role
        @provider = Chef::Provider::KeystoneRole
        @allowed_actions = [:create]

        @action = :create
      end

      def os_token(arg=nil)
        set_or_return(:os_token, arg, :kind_of => String)
      end

      def os_endpoint(arg=nil)
        set_or_return(:os_endpoint, arg, :kind_of => String)
      end
    end

    class KeystoneUser < Chef::Resource

      def initialize(name, run_context=nil)
        super
        @resource_name = :keystone_user
        @provider = Chef::Provider::KeystoneUser
        @allowed_actions = [:create]

        @action = :create
        @enabled = true
      end

      def os_token(arg=nil)
        set_or_return(:os_token, arg, :kind_of => String)
      end

      def os_endpoint(arg=nil)
        set_or_return(:os_endpoint, arg, :kind_of => String)
      end

      def description(arg=nil)
        set_or_return(:description, arg, :kind_of => String)
      end

      def email(arg=nil)
        set_or_return(:email, arg, :kind_of => String)
      end

      def enabled(arg=nil)
        set_or_return(:enabled, arg, :kind_of => [TrueClass, FalseClass])
      end

      def password(arg=nil)
        set_or_return(:password, arg, :kind_of => String)
      end

      def tenant(arg=nil)
        set_or_return(:tenant, arg, :kind_of => String)
      end
    end

    class KeystoneUserRole < Chef::Resource

      def initialize(name, run_context=nil)
        super
        @resource_name = :keystone_user_role
        @provider = Chef::Provider::KeystoneUserRole
        @allowed_actions = [:add]
        @action = :add
      end

      def os_token(arg=nil)
        set_or_return(:os_token, arg, :kind_of => String)
      end

      def os_endpoint(arg=nil)
        set_or_return(:os_endpoint, arg, :kind_of => String)
      end

      def role(arg=nil)
        set_or_return(:role, arg, :kind_of => String)
      end

      def tenant(arg=nil)
        set_or_return(:tenant, arg, :kind_of => String)
      end
    end

    class KeystoneService < Chef::Resource

      def initialize(name, run_context=nil)
        super
        @resource_name = :keystone_service
        @provider = Chef::Provider::KeystoneService
        @allowed_actions = [:create]
        @action = :create
      end

      def os_token(arg=nil)
        set_or_return(:os_token, arg, :kind_of => String)
      end

      def os_endpoint(arg=nil)
        set_or_return(:os_endpoint, arg, :kind_of => String)
      end

      def description(arg=nil)
        set_or_return(:description, arg, :kind_of => String)
      end

      def type(arg=nil)
        set_or_return(:type, arg, :kind_of => String)
      end
    end

    class KeystoneEndpoint < Chef::Resource

      def initialize(name, run_context=nil)
        super
        @resource_name = :keystone_endpoint
        @provider = Chef::Provider::KeystoneEndpoint
        @allowed_actions = [:create]
        @action = :create
      end

      def os_token(arg=nil)
        set_or_return(:os_token, arg, :kind_of => String)
      end

      def os_endpoint(arg=nil)
        set_or_return(:os_endpoint, arg, :kind_of => String)
      end

      def region(arg=nil)
        set_or_return(:region, arg, :kind_of => String)
      end

      def service(arg=nil)
        set_or_return(:service, arg, :kind_of => String)
      end

      def publicurl(arg=nil)
        set_or_return(:publicurl, arg, :kind_of => String)
      end

      def adminurl(arg=nil)
        set_or_return(:adminurl, arg, :kind_of => String)
      end

      def internalurl(arg=nil)
        set_or_return(:internalurl, arg, :kind_of => String)
      end
    end
  end
end
