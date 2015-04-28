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


require 'json'
require 'net/http'


class KeystoneClient

  def initialize(token, endpoint)
    @token = token
    @endpoint = endpoint
  end

  def api_get(uri)
    req = Net::HTTP::Get.new(uri.path)
    Chef::Log.debug "GET: #{uri.path}"
    response = send_request(req, uri)
    Chef::Log.debug "GET reply: #{response}"
    return response
  end

  def api_post(uri, content)
    req = Net::HTTP::Post.new(uri.path)
    req.body = JSON::unparse content
    Chef::Log.debug "POST: #{req.body}"
    req.content_type = 'application/json'
    response = send_request(req, uri)
    Chef::Log.debug "POST reply: #{response}"
    return response
  end

  def api_put(uri)
    req = Net::HTTP::Put.new(uri.path)
    Chef::Log.debug "PUT: #{uri.path}"
    req.content_type = 'application/json'
    response = send_request(req, uri)
    Chef::Log.debug "PUT reply: #{response}"
    return response
  end

  def send_request(request, uri)
    request.add_field('X-Auth-Token', @token)
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    if response.code != '200'
      raise RuntimeError, "#{response.class.name}, #{response.code}, #{response.body}"
    end
    return JSON::parse(response.body)
  end

  def create_uri(type)
    return create_uri_from_path(get_api_path(type))
  end

  def create_uri_from_path(path)
    uri = URI(@endpoint)
    uri.path.concat path
    return uri
  end

  def get_tenant_id_by_name!(name)
    return get_resource_id_by_name!(name, 'tenants')
  end

  def get_role_id_by_name!(name)
    return get_resource_id_by_name!(name, 'roles')
  end

  def get_user_id_by_name!(name)
    return get_resource_id_by_name!(name, 'users')
  end

  def get_service_id_by_name!(name)
    return get_resource_id_by_name!(name, 'OS-KSADM:services')
  end

  def get_resource_id_by_name!(name, type)
    resources = api_get(create_uri(type))
    resources[type].each do |resource|
      if resource['name'] == name
        return resource['id']
      end
    end
    raise RuntimeError, "Resource not found: #{name}"
  end

  def resource_exist?(name, type)
    resources = api_get(create_uri(type))
    names = resources[type].map { |x| x['name'] }
    return names.include?(name)
  end

  def get_api_path(type)
    type_to_path_map = {
      'tenants'           => '/tenants/',
      'roles'             => '/OS-KSADM/roles',
      'users'             => '/users/',
      'endpoints'         => '/endpoints/',
      'OS-KSADM:services' => '/OS-KSADM/services',
    }
    return type_to_path_map[type]
  end
end