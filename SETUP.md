WIP - Intitial and ROUGH  instructions ... to be revised


##Prerequisites
- An existing [service key](https://docs.cloudfoundry.org/devguide/services/service-keys.html) with a corresponding user-provided service containig user/password in its credentials (ie: {"username: "[service-key-username]", "password": "[service-key-password]" )


##Instructions
Cloud Foundry Environment
- Setup a user provided service to store credentials and configure credentials rotator
cups [my-user-provided-service-name]  -p '{"username":"[service-key-username]","password":"[service-key-password]","cloud_gov_service_account_key_guid":"[service-key-guid]","cloud_gov_service_account_key_name":"[service-key-name]","expire_in_days":"60"}'

Note: If you need to change the label of your user and password keys provide the values in attributes "password_label" and "username_label" and the username password keys should use the labels. For example:
{"CF_TEST_USERNAME":"[service-key-password]","password":"[service-key-password]", "password_label":"CF_TEST_PASSWORD","username_label":"CF_TEST_USERNAME", ....}

If storing/updating user/password in CircleCi the following key/value pairs are required:
{...., "circleci_endpoint":"https://circleci.com/api/v1.1/project/github/[github-username]/[github-project-name]","circleci_token":"[circle-ci-api-token]", ...}


CircleCI Setup
Add environment variables containing login details for Cloud Foundry API
CF_API
CF_TEST_USERNAME
CF_TEST_PASSWORD
CF_ORGANIZATION
CF_SPACE

Update /.circleci/config.yml
In the first jobs section add a command entry per user-provided-service/service-key you want to rotate:
- run:
          name: Rotate the credentials for my servie
          command: ruby rotate_creds.rb my_service

- Update the schedule section as appropriate
