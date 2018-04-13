require 'json'
require 'date'

def get_service_key(guid)
	JSON.parse(`cf curl /v2/service_keys/#{guid}`)
end

def get_service_keys(service_instance_guid)
	JSON.parse(`cf curl /v2/service_keys?q=service_instance_guid:#{service_instance_guid}`).to_h['resources']
end

def get_service_intsance(service_instance_guid)
	si = JSON.parse(`cf curl /v2/service_instances/#{service_instance_guid}`)
	unless si
		si = JSON.parse(`cf curl /v2/service_instances?q=name:#{service_instance_guid}`)
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


ARGV.each do |service_instance_guid|
  puts "Argument: #{service_instance_guid}"
  keys = get_service_keys(service_instance_guid)

	puts "keys => #{keys}\n\n"

	# if keys.any?
	# 	key = get_service_key(keys.first.to_h["metadata"].to_h["guid"])

	# 	puts "key => #{key}\n\n"

	# 	service_instance_guid = key['entity'].to_h["service_instance_guid"]

	# 	if service_instance_guid
	# 		puts "service_instance_guid  => #{service_instance_guid}\n\n"

	# 		service_instance = get_service_intsance(service_instance_guid)

	# 		puts "service_instance => #{service_instance}\n\n"
	# 	end
	# end
	
	service_instance = get_service_intsance(service_instance_guid)
	service_name = service_instance['entity'].to_h['name']

	puts "service_name => #{service_name}"

	new_creds = refresh_service_key(service_name)

	puts new_creds.inspect
end