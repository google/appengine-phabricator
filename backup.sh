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

# This file defines a supervisord event listener which backs up the "/var/repo"
# directory to GCS.
#
# Note that this assumes that it is only sent header lines with no event payloads,
# so it should only be used for events that have no body (such as TICK_N).

PROJECT=$(curl http://metadata.google.internal/computeMetadata/v1/project/project-id -H 'Metadata-Flavor: Google')
echo "READY"

while read line; do
  echo "RESULT 2"
  echo "OK"

  BACKUP_FILE="repo-backup-$(date --iso-8601=seconds).tgz"

  echo "Creating backup file ${BACKUP_FILE}" 1>&2
  tar -cvzf /tmp/"$BACKUP_FILE" /var/repo

  # TODO(ojarjur): Support incremental backups
  echo "Copying backup file to gs://${PROJECT}.appspot.com/backups/${BACKUP_FILE}" 1>&2
  /google/google-cloud-sdk/bin/gsutil cp /tmp/"$BACKUP_FILE" gs://${PROJECT}.appspot.com/backups/${BACKUP_FILE}
  rm /tmp/"${BACKUP_FILE}"

  PREVIOUS_BACKUP=$(/google/google-cloud-sdk/bin/gsutil cat gs://${PROJECT}.appspot.com/backups/phabricator.backup)
  echo "gs://${PROJECT}.appspot.com/backups/${BACKUP_FILE}" | /google/google-cloud-sdk/bin/gsutil cp - gs://${PROJECT}.appspot.com/backups/phabricator.backup
  /google/google-cloud-sdk/bin/gsutil rm ${PREVIOUS_BACKUP}

  echo "READY"
done
