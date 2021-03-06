require 'date'
require './credentials_requests.rb'
# require 'byebug'

def delete_old_service_keys(user_provided_service_name_or_guid, days = 90)
	service_instance = get_user_provided_service(user_provided_service_name_or_guid)
	latest_service_key = get_service_key(service_instance['entity']['credentials']['SERVICE_KEY_GUID'])

	deployer_service = get_service_instance(latest_service_key['entity']["service_instance_guid"])

	service_keys = get_service_keys(deployer_service['metadata']['guid'])
	while service_keys['resources'].to_a.any?
		service_keys['resources'].select{|sk| (Date.today - Date.parse(sk['metadata']['created_at'])).to_i > days.to_i}.each do |sk|
			delete_service_key(deployer_service['entity']['name'], sk['entity']['name'])
		end
		break unless service_keys['next_url']
		service_keys = JSON.parse(`cf curl "#{service_keys['next_url']}"`)
	end
end

delete_old_service_keys(ARGV[0], ARGV[1] || 90)