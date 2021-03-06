require 'json'
require 'date'
require './credentials_requests.rb'
# require 'byebug'

ARGV.each do |user_provided_service_instance_name|
  puts "Argument: #{user_provided_service_instance_name}"
	user_provided_service_instance = get_user_provided_service(user_provided_service_instance_name)
	if user_provided_service_instance

		service_key_name = user_provided_service_instance['entity']['credentials']['SERVICE_KEY_NAME']
		service_key_guid = user_provided_service_instance['entity']['credentials']['SERVICE_KEY_GUID']

		service_key = get_service_key(service_key_guid)

		if (Date.today - Date.parse(service_key['metadata']['created_at'])).to_i >= (user_provided_service_instance['entity']['credentials'].to_h["EXPIRE_IN_DAYS"] || 75).to_i
			service_account = get_service_instance(service_key['entity']['service_instance_guid'])

			service_key_creds = refresh_service_key(service_account['entity']['name'])

			new_service_key = find_service_key(service_account['metadata']['guid'], service_key_creds['username'], service_key_creds['password'])
			#use username and passord values as expected

			user_provided_service_instance['entity']['credentials'][user_provided_service_instance['entity']['credentials']["USERNAME_LABEL"] || 'SERVICE_KEY_USERNAME'] = new_service_key['entity']['credentials']['username']
			user_provided_service_instance['entity']['credentials'][user_provided_service_instance['entity']['credentials']["PASSWORD_LABEL"] || 'SERVICE_KEY_PASSWORD'] = new_service_key['entity']['credentials']['password']		
			
			user_provided_service_instance['entity']['credentials']['SERVICE_KEY_GUID'] = new_service_key['metadata']['guid']
			user_provided_service_instance['entity']['credentials']['SERVICE_KEY_NAME'] = new_service_key['entity']['name']
			user_provided_service_instance['entity']['credentials']['SERVICE_KEY_CREATED'] = new_service_key['metadata']['created_at']
			cmd = "cf uups #{user_provided_service_instance['entity']['name']} -p '#{user_provided_service_instance['entity']['credentials'].to_json}'"

			if `#{cmd}` =~ /OK/
				puts "\n\n#{user_provided_service_instance['entity']['name']} - Updated credentials Successfully\n\n"
			else
				raise "\n\nFAILED: #{user_provided_service_instance['entity']['name']} - Updating credentials FAILED!!!\n\n"
				exit
			end

			#refresh user_provided_service_instance
			user_provided_service_instance = get_user_provided_service(user_provided_service_instance['metadata']['guid'])

			if user_provided_service_instance['entity']['credentials']["CIRCLECI_ENDPOINT"]# && user_provided_service_instance['entity']['credentials']['username_label']# && user_provided_service_instance['entity']['credentials']['password_label']
				if user_provided_service_instance['entity']['credentials']["USERNAME_LABEL"].nil? || user_provided_service_instance['entity']['credentials']["PASSWORD_LABEL"].nil?
					raise "FAILED (CircleCI): Username and password labels are required for updating password credentials on CircleCI!!!\n\tCheck your #{user_provided_service_instance['entity']['name']} service credentials"
				else
					env_vars = []
					env_vars << {name: user_provided_service_instance['entity']['credentials']["USERNAME_LABEL"], value: user_provided_service_instance['entity']['credentials'][user_provided_service_instance['entity']['credentials']["USERNAME_LABEL"]]}
					env_vars << {name: user_provided_service_instance['entity']['credentials']["PASSWORD_LABEL"], value: user_provided_service_instance['entity']['credentials'][user_provided_service_instance['entity']['credentials']["PASSWORD_LABEL"]]}
					env_vars.each do |ev|
						cmd = "curl -X POST --header \"Content-Type: application/json\" -d '#{ev.to_json}' #{user_provided_service_instance['entity']['credentials']["CIRCLECI_ENDPOINT"]}envvar?circle-token=#{user_provided_service_instance['entity']['credentials']["CIRCLECI_TOKEN"]}"
						val =  `#{cmd}`
						raise "FAILED (CircleCI): Unable to save #{ev[:name]}" unless ev[:value].end_with?(JSON.parse(val)['value'][-4,4])
						sleep(5)
					end
				end
			end
		end
	end
end