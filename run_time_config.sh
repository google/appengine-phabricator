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
mkdir -p /var/log/app_engine/custom_logs

cd /opt/phabricator
export SQL_DETAILS="$(/google/google-cloud-sdk/bin/gcloud sql instances describe ${SQL_INSTANCE} --format=json)"
echo "${SQL_DETAILS}" >> /var/log/app_engine/custom_logs/setup.log

export SQL_HOST=$(echo ${SQL_DETAILS} | jq -r '.ipAddresses[0].ipAddress')
export SQL_USER=root
echo "Setting up a connection to ${SQL_INSTANCE} at ${SQL_HOST} as ${SQL_USER}" >> /var/log/app_engine/custom_logs/setup.log

export SQL_PASS="$(uuidgen)"
/google/google-cloud-sdk/bin/gcloud sql instances set-root-password \
  --password "${SQL_PASS}" "${SQL_INSTANCE}"

# Configure Phabricator's connection to the SQL server.
./bin/config set mysql.host ${SQL_HOST}
./bin/config set mysql.port 3306
./bin/config set mysql.user ${SQL_USER}
./bin/config set mysql.pass ${SQL_PASS}

# And setup the .my.cnf file so that mysql commands are authenticated.
cat > ~/.my.cnf <<EOF
[client]
host=${SQL_HOST}
user=${SQL_USER}
password=${SQL_PASS}
EOF

# Configure Phabricator's reference to itself.
./bin/config set phabricator.base-uri ${PHABRICATOR_BASE_URI}
./bin/config set security.alternate-file-domain ${ALTERNATE_FILE_DOMAIN}
./bin/config set phd.taskmasters 4