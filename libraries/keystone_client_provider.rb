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


require_relative 'keystone.rb'


class Chef
  class Provider
    class KeystoneTenant < Chef::Provider

      def load_current_resource
        @current_resource ||= Chef::Resource::KeystoneTenant.new new_resource.name
        @current_resource.os_endpoint new_resource.os_endpoint
        @current_resource.os_token    new_resource.os_token
        @current_resource.description new_resource.description
        @current_resource.enabled     new_resource.enabled
        return @current_resource
      end

      def action_create
        if not tenant_exist?
          attributes = {
            :tenant => {
              :enabled     => @current_resource.enabled,
              :name        => @current_resource.name,
              :description => @current_resource.description
            }
          }

          client.api_post(client.create_uri('tenants'), attributes)
          Chef::Log.info "Tenant #{@current_resource.name} successfully created"
        else
          Chef::Log.info "Tenant #{@current_resource.name} already exists"
        end
      end

      private

      def client
        KeystoneClient.new(@current_resource.os_token, @current_resource.os_endpoint)
      end

      def tenant_exist?
        return client.resource_exist?(@current_resource.name, 'tenants')
      end
    end

    class KeystoneRole < Chef::Provider

      def load_current_resource
        @current_resource ||= Chef::Resource::KeystoneTenant.new new_resource.name
        @current_resource.os_endpoint new_resource.os_endpoint
        @current_resource.os_token    new_resource.os_token
        return @current_resource
      end

      def action_create
        if not role_exist?
          attributes = {
            :role => {
              :name => @current_resource.name,
            }
          }
          client.api_post client.create_uri('roles'), attributes
          Chef::Log.info "Role #{@current_resource.name} successfully created"
        else
          Chef::Log.info "Role #{@current_resource.name} already exists"
        end
      end

      private

      def client
        KeystoneClient.new(@current_resource.os_token, @current_resource.os_endpoint)
      end

      def role_exist?
        return client.resource_exist?(@current_resource.name, 'roles')
      end
    end

    class KeystoneUser < Chef::Provider

      def load_current_resource
        @current_resource ||= Chef::Resource::KeystoneUser.new new_resource.name
        @current_resource.os_endpoint new_resource.os_endpoint
        @current_resource.os_token    new_resource.os_token
        @current_resource.email       new_resource.email
        @current_resource.enabled     new_resource.enabled
        @current_resource.password    new_resource.password
        @current_resource.tenant      new_resource.tenant
        return @current_resource
      end

      def action_create
        if not user_exist?
          attributes = {
            :user => {
              :enabled  => @current_resource.enabled,
              :name     => @current_resource.name,
              :tenantId => nil,
              :password => @current_resource.password,
              :email    => @current_resource.email,
            }
          }

          if @current_resource.tenant
            attributes[:user][:tenantId] = \
              client.get_tenant_id_by_name!(@current_resource.tenant)
          end

          client.api_post client.create_uri('users'), attributes
          Chef::Log.info "User #{@current_resource.name} successfully created"
        else
          Chef::Log.info "User #{@current_resource.name} already exists"
        end
      end

      private

      def client
        KeystoneClient.new(@current_resource.os_token, @current_resource.os_endpoint)
      end

      def user_exist?
        return client.resource_exist?(@current_resource.name, 'users')
      end
    end

    class KeystoneUserRole < Chef::Provider

      def load_current_resource
        @current_resource ||= Chef::Resource::KeystoneUserRole.new new_resource.name
        @current_resource.os_endpoint new_resource.os_endpoint
        @current_resource.os_token    new_resource.os_token
        @current_resource.role        new_resource.role
        @current_resource.tenant      new_resource.tenant
        return @current_resource
      end

      def action_add
        attributes = {
          :tenant_id => client.get_tenant_id_by_name!(@current_resource.tenant),
          :user_id   => client.get_user_id_by_name!(@current_resource.name),
          :role_id   => client.get_role_id_by_name!(@current_resource.role),
        }

        if not user_has_role? attributes
          client.api_put client.create_uri_from_path('/tenants/%{tenant_id}/users/%{user_id}/roles/OS-KSADM/%{role_id}' % attributes)
          Chef::Log.info "Role #{@current_resource.role} asigned to user #{@current_resource.name}"
        else
          Chef::Log.info "User #{@current_resource.name} already have role #{@current_resource.role}"
        end
      end

      private

      def client
        KeystoneClient.new(@current_resource.os_token, @current_resource.os_endpoint)
      end

      def user_has_role?(attributes)
        roles = client.api_get client.create_uri_from_path('/tenants/%{tenant_id}/users/%{user_id}/roles' % attributes)
        names = roles['roles'].map { |x| x['name'] }
        return names.include?(@current_resource.role)
      end
    end

    class KeystoneService < Chef::Provider

      def load_current_resource
        @current_resource ||= Chef::Resource::KeystoneService.new new_resource.name
        @current_resource.os_endpoint new_resource.os_endpoint
        @current_resource.os_token    new_resource.os_token
        @current_resource.type        new_resource.type
        @current_resource.description new_resource.description
        return @current_resource
      end

      def action_create
        if not service_exist?
          attributes = {
            :'OS-KSADM:service' => {
              :type        => @current_resource.type,
              :name        => @current_resource.name,
              :description => @current_resource.description,
            }
          }
          client.api_post client.create_uri('OS-KSADM:services'), attributes
          Chef::Log.info "Service #{@current_resource.name} successfully created"
        else
          Chef::Log.info "Service #{@current_resource.name} already exists"
        end
      end

      private

      def client
        KeystoneClient.new(@current_resource.os_token, @current_resource.os_endpoint)
      end

      def service_exist?
        return client.resource_exist?(@current_resource.name, 'OS-KSADM:services')
      end
    end

    class KeystoneEndpoint < Chef::Provider

      def load_current_resource
        @current_resource ||= Chef::Resource::KeystoneEndpoint.new new_resource.name
        @current_resource.os_endpoint new_resource.os_endpoint
        @current_resource.os_token    new_resource.os_token
        @current_resource.region      new_resource.region
        @current_resource.service     new_resource.service
        @current_resource.publicurl   new_resource.publicurl
        @current_resource.adminurl    new_resource.adminurl
        @current_resource.internalurl new_resource.internalurl
        return @current_resource
      end

      def action_create
        service_id = client.get_service_id_by_name! @current_resource.service
        if not endpoint_exist? service_id
          attributes = {
            :endpoint => {
              :region      => 'regionOne',
              :service_id  => service_id,
              :adminurl    => @current_resource.adminurl,
              :internalurl => @current_resource.internalurl,
              :publicurl   => @current_resource.publicurl,
            }
          }

          if @current_resource.region
            attributes[:endpoint][:region] = @current_resource.region
          end

          client.api_post client.create_uri('endpoints'), attributes
          Chef::Log.info "Endpoint #{@current_resource.name} successfully created"
        else
          Chef::Log.info "Endpoint #{@current_resource.name} already exists"
        end
      end

      private

      def client
        KeystoneClient.new(@current_resource.os_token, @current_resource.os_endpoint)
      end

      def endpoint_exist?(service_id)
        resources = client.api_get(client.create_uri('endpoints'))
        ids = resources['endpoints'].map { |x| x['service_id'] }
        return ids.include?(service_id)
      end
    end
  end
end
