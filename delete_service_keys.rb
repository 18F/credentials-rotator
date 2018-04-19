require 'date'
require './credentials_requests.rb'
require 'byebug'

def delete_old_service_keys(user_provided_service_name_or_guid, days = 90)
	service_instance = get_user_provided_service(user_provided_service_name_or_guid)
	latest_service_key = get_service_key(service_instance['entity']['credentials']['cloud_gov_service_account_key_guid'])
	deployer_service = get_service_instance(latest_service_key['entity']["service_instance_guid"])

	service_keys = get_service_keys(deployer_service['metadata']['guid'])

	service_keys.select{|sk| (Date.today - Date.parse(service_instance['metadata']['created_at'])).to_i > days.to_i}.each do |sk| 
		delete_service_key(service_instance['entity']['name'], sk['entity']['name'])
	end
end

delete_old_service_keys(ARGV[0], ARGV[1])