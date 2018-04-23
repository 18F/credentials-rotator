require 'json'
require 'date'


def get_service_key(guid)
	JSON.parse(`cf curl /v2/service_keys/#{guid}`)
end

def find_service_key(service_instance_guid, username, password)
	service_key = nil
	service_keys = get_service_keys(service_instance_guid)
	while !service_key
		service_key = service_keys['resources'].to_a.select{|keys| (keys['entity']['credentials']['username'] == username) && (keys['entity']['credentials']['password'] == password)}.first
		break unless service_keys['next_url']
		service_keys = JSON.parse(`cf curl "#{service_keys['next_url']}"`)
	end
	service_key
end

def get_service_keys(service_instance_guid, page = 0)
	JSON.parse(`cf curl /v2/service_instances/#{service_instance_guid}/service_keys`).to_h
end

def get_service_instance(service_instance_guid)
	si = JSON.parse(`cf curl /v2/service_instances/#{service_instance_guid}`).to_h
	if si.empty?
		si = JSON.parse(`cf curl /v2/service_instances?q=name:#{service_instance_guid}`).to_h['resources'].to_a.first.to_h
	end
	si
end

def refresh_service_key(service_instance_name)
	service_key = "#{service_instance_name}-#{DateTime.now.strftime("%Y%m%d%H%M%S")}"
	`cf create-service-key #{service_instance_name} #{service_key}`
	puts "fetching => service-key #{service_instance_name} #{service_key}"
	sk = `cf service-key #{service_instance_name} #{service_key}`
	puts sk
	JSON.parse(sk[(sk.index("\n\n")),1000])
end

def get_user_provided_service(service_instance_guid = nil)
	endpoint = "cf curl /v2/user_provided_service_instances"
	if service_instance_guid
		ups = JSON.parse(`#{endpoint}/#{service_instance_guid}`).to_h
		unless ups['entity']
			ups = JSON.parse(`#{endpoint}?q=name:#{service_instance_guid}`).to_h['resources'].first
		end
	else
		ups = JSON.parse(`#{endpoint}`).to_h
	end
	ups
end

def delete_service_key(server_instance_name, service_key)
	`cf delete-service-key #{server_instance_name} #{service_key} -f`
end