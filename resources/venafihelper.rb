resource_name :venafihelper

property :common_name, String, name_property: true
property :tpp_url, String
property :tpp_password, String
property :tpp_username, String
property :zone, String
property :location, String
property :device_name, String, default: node['fqdn']
property :app_name, String
property :apikey, String
property :id_path, String
property :app_info, String
property :tls_address, String
property :renew_threshold, Integer

action :run do
  app_name = new_resource.app_name
  instance = new_resource.device_name
  instance = "#{instance}:#{app_name}" if app_name

  common_name = new_resource.common_name
  cert_file = "#{common_name}.cert"
  key_file = "#{common_name}.key"
  chain_file = "#{common_name}.chain"
  id_file = "#{common_name}.id"

  location = new_resource.location
  id_path = new_resource.id_path
  cert_path = "#{location}/#{cert_file}"
  key_path = "#{location}/#{key_file}"
  chain_path = "#{location}/#{chain_file}"
  id_path = "#{location}/#{id_file}"

  if !instance.nil? && !new_resource.app_info.nil? && !new_resource.tls_address.nil? && !apikey.nil?
    ::Chef::Application.fatal!('Device Registration not supported on Venafi Cloud')
  end

  remote_file venafi_install_path do
    source venafi_download_url
    mode '0755'
    action :create
  end

  directory location

  execute 'enroll' do
    command enroll(
      apikey: new_resource.apikey,
      zone: new_resource.zone,
      cert_path: cert_path,
      key_path: key_path,
      chain_path: chain_path,
      common_name: common_name,
      id_path: id_path,
      tpp_username: new_resource.tpp_username,
      tpp_password: new_resource.tpp_password,
      tpp_url: new_resource.tpp_url,
      instance: instance,
      app_info: new_resource.app_info,
      tls_address: new_resource.tls_address
    )
    sensitive true
    not_if { ::File.exist?(cert_path) && ::File.exist?(key_path) && ::File.exist?(chain_path) }
  end

  execute 'renew' do
    command renew(
      apikey: new_resource.apikey,
      zone: new_resource.zone,
      cert_path: cert_path,
      key_path: key_path,
      chain_path: chain_path,
      common_name: common_name,
      id_path: id_path,
      tpp_username: new_resource.tpp_username,
      tpp_password: new_resource.tpp_password,
      tpp_url: new_resource.tpp_url
    )
    sensitive true
    only_if { should_renew?(cert_path: cert_path, renew_threshold: new_resource.renew_threshold) }
  end
end

action_class do
  include VenafiCookbook::Helper
end
