#!/bin/bash -e
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

# Variables defining the deployment target
PROJECT=$1
VERSION=1

# Local tag for the Docker image we deploy
LOCAL_IMAGE="google/phabricator-appengine"

function defaultModuleExists() {
  local project=$1
  local count=$(gcloud preview app modules list default --project $project 2>&1 \
    | grep -o "^default" | wc -l)
  if [[ $count -gt 0 ]]; then
    return 0
  else
    return 1
  fi
}

function deployDefaultModule() {
  local target_project=$1
  local tmp_dir=$(mktemp -d --tmpdir=$(pwd))
  echo
  echo "Default module doesn't exist, deploying default module now..."
  cat > ${tmp_dir}/app.yaml <<EOF
module: default
runtime: python27
api_version: 1
threadsafe: true
handlers:
- url: /
  mime_type: text/html
  static_files: hello.html
  upload: (.*html)
EOF

  cat > ${tmp_dir}/hello.html <<EOF
<html>
  <head>
    <title>Sample Hello-World Page.</title>
  </head>
  <body>
    Hello, World!
  </body>
</html>
EOF
  local status=1
  gcloud preview app deploy --force --quiet --project $target_project \
    $tmp_dir/app.yaml --version v1
  [[ $? ]] && status=0 || echo "Failed to deploy default module to $target_project"
  rm -rf $tmp_dir
  return $status
}

if ! defaultModuleExists $PROJECT; then
  if ! deployDefaultModule $PROJECT; then
    exit
  fi
fi

# If we have a local image, then push it to gcr.io and update the Dockerfile
if [ -n "$(docker images -q --all ${LOCAL_IMAGE})" ]; then
  export REMOTE_IMAGE="gcr.io/${PROJECT}/appengine-phabricator"
  export ESCAPED_REMOTE_IMAGE="gcr\.io\/${PROJECT}\/appengine-phabricator"

  # Push the local image to the project's gcr.io repo
  docker tag -f ${LOCAL_IMAGE} ${REMOTE_IMAGE}
  gcloud docker push ${REMOTE_IMAGE}

  # Update the Dockerfile to point at that newly pushed image
  sed -i -e "s/gcr\.io\/developer_tools_bundle\/bundle-phabricator/${ESCAPED_REMOTE_IMAGE}/" config/Dockerfile
fi

# Ensure that a Cloud SQL instance exists
if [ -z "$(gcloud --project=${PROJECT} sql instances list | grep phabricator)" ]; then
  gcloud --quiet --project="${PROJECT}" sql instances create "phabricator" \
    --backup-start-time="00:00" \
    --assign-ip \
    --authorized-networks "0.0.0.0/0" \
    --tier="D1" \
    --pricing-plan="PACKAGE" \
    --database-flags="sql_mode=STRICT_ALL_TABLES,ft_min_word_len=3"
fi

INSTANCE_NAME=$(gcloud --project="${PROJECT}" sql instances list | grep phabricator | cut -d " " -f 1)
if [ -z "${INSTANCE_NAME}" ]; then
  # We could not load the name of the Cloud SQL instance, so we need to bail out.
  echo "Failed to load the name of the Cloud SQL instance to use for Phabricator"
  exit
fi

# Ensure that a private networks exists for Phabricator
if [ -z "$(gcloud --project=${PROJECT} compute networks list | grep phabricator)" ]; then
  gcloud --project="${PROJECT}" compute networks create phabricator --range "10.0.0.0/24"
fi

# Set the appropriate environment variables in the app.yaml file
sed -i -e "s/\${SQL_INSTANCE}/${INSTANCE_NAME}/" \
  -e "s/\${PROJECT}/${PROJECT}/" \
  -e "s/\${VERSION}/${VERSION}/" config/app.yaml
gcloud --project="${PROJECT}" --quiet preview app deploy --version=${VERSION} --set-default config/app.yaml
git checkout -- config/app.yaml config/Dockerfile
