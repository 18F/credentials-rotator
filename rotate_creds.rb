require 'json'
require 'date'
require './credentials_requests.rb'
# require 'byebug'

ARGV.each do |user_provided_service_instance_name|
  puts "Argument: #{user_provided_service_instance_name}"
	user_provided_service_instance = get_user_provided_service(user_provided_service_instance_name)
	if user_provided_service_instance

		service_key_name = user_provided_service_instance['entity']['credentials']['cloud_gov_service_account_key_name']
		service_key_guid = user_provided_service_instance['entity']['credentials']['cloud_gov_service_account_key_guid']

		service_key = get_service_key(service_key_guid)

		if (Date.today - Date.parse(service_key['metadata']['created_at'])).to_i > (user_provided_service_instance['entity']['credentials'].to_h['expire_in_days'] || 75).to_i
			cloud_gov_service_account = get_service_instance(service_key['entity']['service_instance_guid'])

			service_key_creds = refresh_service_key(cloud_gov_service_account['entity']['name'])

			new_service_key = find_service_key(cloud_gov_service_account['metadata']['guid'], service_key_creds['username'], service_key_creds['password'])
			#use username and passord values as expected

			user_provided_service_instance['entity']['credentials'][user_provided_service_instance['entity']['credentials']['username_label'] || 'username'] = new_service_key['entity']['credentials']['username']
			user_provided_service_instance['entity']['credentials'][user_provided_service_instance['entity']['credentials']['password_label'] || 'password'] = new_service_key['entity']['credentials']['password']		
			
			user_provided_service_instance['entity']['credentials']['rotated_at'] = new_service_key['metadata']['created_at']
			user_provided_service_instance['entity']['credentials']['cloud_gov_service_account_key_guid'] = new_service_key['metadata']['guid']
			user_provided_service_instance['entity']['credentials']['cloud_gov_service_account_key_name'] = new_service_key['entity']['name']
			user_provided_service_instance['entity']['credentials']['last_checked'] = DateTime.now.to_s
			cmd = "cf uups #{user_provided_service_instance['entity']['name']} -p '#{user_provided_service_instance['entity']['credentials'].to_json}'"
			puts cmd
			if `#{cmd}` =~ /OK/
				puts "\n\n#{user_provided_service_instance['entity']['name']} - Updated credentials Successfully\n\n"
			else
				raise "\n\nFAILED: #{user_provided_service_instance['entity']['name']} - Updating credentials FAILED!!!\n\n"
				exit
			end

			#refresh user_provided_service_instance
			user_provided_service_instance = get_user_provided_service(user_provided_service_instance['metadata']['guid'])

			if user_provided_service_instance['entity']['credentials']['circleci_endpoint']# && user_provided_service_instance['entity']['credentials']['username_label']# && user_provided_service_instance['entity']['credentials']['password_label']
				if user_provided_service_instance['entity']['credentials']['username_label'].nil? || user_provided_service_instance['entity']['credentials']['password_label'].nil?
					raise "FAILED (CircleCI): Username and password labels are required for updating password credentials on CircleCI!!!\n\tCheck your #{user_provided_service_instance['entity']['name']} service credentials"
				else
					env_vars = []
					env_vars << {name: user_provided_service_instance['entity']['credentials']['username_label'], value: user_provided_service_instance['entity']['credentials'][user_provided_service_instance['entity']['credentials']['username_label']]}
					env_vars << {name: user_provided_service_instance['entity']['credentials']['password_label'], value: user_provided_service_instance['entity']['credentials'][user_provided_service_instance['entity']['credentials']['password_label']]}
					env_vars << {name: "#{user_provided_service_instance['entity']['credentials']['password_label']}_CREATED", value: user_provided_service_instance['entity']['credentials']['created_at']}
					env_vars.each do |ev|
						cmd = "curl -X POST --header \"Content-Type: application/json\" -d '#{ev.to_json}' #{user_provided_service_instance['entity']['credentials']['circleci_endpoint']}/envvar?circle-token=#{user_provided_service_instance['entity']['credentials']['circleci_token']}"
						puts cmd
						puts `#{cmd}`
						sleep(5)
					end
				end
			end
		else
			user_provided_service_instance['entity']['credentials'].merge!({"last_checked" => DateTime.now.to_s})
			cmd = "cf uups #{user_provided_service_instance['entity']['name']} -p '#{user_provided_service_instance['entity']['credentials'].to_json}'"
			puts cmd
			if `#{cmd}` =~ /OK/
				puts "\n\n#{user_provided_service_instance['entity']['name']} - Updated Successfully\n\n"
			else
				raise "\n\nFAILED: #{user_provided_service_instance['entity']['name']} - Updating last checked timestamp #{user_provided_service_instance['entity']['name']} FAILED!!!\n\n"
			end				
		end
	end
end