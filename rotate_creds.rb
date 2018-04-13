require 'json'
require 'date'
# require 'byebug'

def get_service_key(guid)
	JSON.parse(`cf curl /v2/service_keys/#{guid}`)
end

def get_service_keys(service_instance_guid)
	JSON.parse(`cf curl /v2/service_keys?q=service_instance_guid:#{service_instance_guid}`).to_h['resources']
end

def get_service_instance(service_instance_guid)
	si = JSON.parse(`cf curl /v2/service_instances/#{service_instance_guid}`).to_h['resources'].to_a
	if si.empty?
		si = JSON.parse(`cf curl /v2/service_instances?q=name:#{service_instance_guid}`).to_h['resources'].to_a
	end
	si.first
end

def refresh_service_key(service_instance_name)
	service_key = "#{service_instance_name}-#{DateTime.now.strftime("%Y%m%d%H%M%S")}"
	`cf create-service-key #{service_instance_name} #{service_key}`
	puts "fetching => service-key #{service_instance_name} #{service_key}"
	sk = `cf service-key #{service_instance_name} #{service_key}`
	puts sk
	sk = JSON.parse(sk[(sk.index("\n\n")),1000])
	if sk.any?
		sk['service_key_name'] = service_key
		sk['service_key_created'] = Date.today.to_s
		sk['service_instance'] = service_instance_name
	end
	sk
end


ARGV.each do |service_instance_guid|
  puts "Argument: #{service_instance_guid}"
  

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
	
	service_instance = get_service_instance(service_instance_guid)
	if service_instance
		# keys = get_service_keys(service_instance['metadata']['guid'])

		# puts "keys => #{keys}\n\n"

		service_name = service_instance['entity'].to_h['name']

		if service_name
			puts "service_name => #{service_name}"
			new_creds = refresh_service_key(service_name)
		end

		circle_token = "<CIRCLE TOKEN>"
		user_provided_service_name = 'builder_test'
		if new_creds.any?
			puts new_creds
			if user_provided_service_name.to_s !~ /circle/
				cmd = "cf uups #{user_provided_service_name} -p '#{new_creds.to_json}'"
				puts cmd
				`#{cmd}`
			else
				env_vars = []
				env_vars << {name: "CF_TEST_USERNAME", value: new_creds['username']}
				env_vars << {name: "CF_TEST_PASSWORD", value: new_creds['password']}
				env_vars << {name: "CF_TEST_CREATED", value: new_creds['service_key_created']}
				env_vars.each do |ev|
					cmd = "curl -X POST --header \"Content-Type: application/json\" -d '#{ev.to_json}' https://circleci.com/api/v1.1/project/github/18F/federalist/envvar?circle-token=#{circle_token}"
					puts cmd
					`#{cmd}`
					sleep(5)
				end
			end
			
		end
	end
end