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

# Variables defining the deployment target
PROJECT=$1
VERSION=1

# Local tag for the Docker image we deploy
DOCKER_TAG="google/phabricator-appengine"

# Ensure that we have a local image to deploy
if [ -z "$(docker images -q --all ${DOCKER_TAG})" ]; then
  docker pull gcr.io/developer_tools_bundle/bundle-phabricator:latest
  docker tag gcr.io/developer_tools_bundle/bundle-phabricator:latest ${DOCKER_TAG}
fi

# Ensure that a Cloud SQL instance exists
if [ -z "$(gcloud --project=${PROJECT} sql instances list | grep phabricator)" ]; then
  gcloud --project="${PROJECT}" sql instances create "phabricator" \
    --backup-start-time="00:00" \
    --require-ssl \
    --assign-ip \
    --authorized-networks "0.0.0.0/0" \
    --tier="D1" \
    --pricing-plan="PACKAGES" \
    --database-flags="sql_mode=STRICT_ALL_TABLES,ft_min_word_len=3"
fi
INSTANCE_NAME=$(gcloud --project="${PROJECT}" sql instances list | grep phabricator | cut -d " " -f 1)

# Ensure that a private networks exists for Phabricator
if [ -z "$(gcloud --project=${PROJECT} compute networks list | grep phabricator)" ]; then
  gcloud --project="${PROJECT}" compute networks create phabricator
fi

# Set the appropriate environment variables in the app.yaml file
sed -i -e "s/\${SQL_INSTANCE}/${INSTANCE_NAME}/" \
  -e "s/\${PROJECT}/${PROJECT}/" \
  -e "s/\${VERSION}/${VERSION}/" config/app.yaml
gcloud --project="${PROJECT}" --quiet preview app deploy --version=${VERSION} --set-default config/app.yaml
git checkout -- config/app.yaml