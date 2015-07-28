#!/bin/bash
# Copyright 2015 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

PHABRICATOR_BASE_URI=$(/opt/phabricator/bin/config get phabricator.base-uri | grep appspot.com | cut -d '"' -f 4)

# Fetch the conduit certificate for the "git-mirror" user. First we just try
# the simple get in case that user already exists, and if that fails we create
# that user and try again.
CONDUIT_CERT=$(mysql -e 'select conduitCertificate from phabricator_user.user where userName="git-mirror";' -Ns)
if [ -z "${CONDUIT_CERT}" ]; then
  echo "No git-mirror user exists; creating one..."
  PROJECT="$(curl http://metadata.google.internal/computeMetadata/v1/project/project-id -H 'Metadata-Flavor: Google')"
  /opt/phabricator/scripts/user/create_bot.php git-mirror "git-mirror@phabricator-dot-${PROJECT}.appspot.com" "Git/Phabricator Mirroring Tool" || exit 1
  echo "Successfully created the git-mirror user"
  CONDUIT_CERT=$(mysql -e 'select conduitCertificate from phabricator_user.user where userName="git-mirror";' -Ns)
fi

# Set up the ~/.arcrc file so that we can run the git-mirror robot in this same container
cp /opt/.arcrc ~/.arcrc
sed -i -e "s/_PHABRICATOR_BASE_URI_/${PHABRICATOR_BASE_URI}/g" ~/.arcrc
sed -i -e "s/_CONDUIT_CERT_/${CONDUIT_CERT}/g" ~/.arcrc
chmod 600 ~/.arcrc
echo "Wrote out an arcanist config for the git-mirror user to ~/.arcrc"
