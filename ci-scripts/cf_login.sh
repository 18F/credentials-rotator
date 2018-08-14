#!/bin/bash

set -e

CF_ORGANIZATION="gsa-18f-federalist"
CF_API="https://api.fr.cloud.gov"

# install cf cli
curl -L -o cf-cli_amd64.deb 'https://cli.run.pivotal.io/stable?release=debian64&source=github'
sudo dpkg -i cf-cli_amd64.deb
rm cf-cli_amd64.deb

# install autopilot
cf install-plugin autopilot -f -r CF-Community

cf api $CF_API


if [ "$CIRCLE_BRANCH" == "master" ]; then
  CF_SPACE="production"
  cf login -u $CF_USERNAME_PRODUCTION -p $CF_PASSWORD_PRODUCTION -o $CF_ORGANIZATION -s $CF_SPACE
elif [ "$CIRCLE_BRANCH" == "staging" ]; then
  CF_SPACE="staging"
  cf login -u $CF_USERNAME_STAGING -p $CF_PASSWORD_STAGING -o $CF_ORGANIZATION -s $CF_SPACE
else
  echo "Current branch has no associated environment to rotate. Exiting."
  exit
fi
# cf logout
