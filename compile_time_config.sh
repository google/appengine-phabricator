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

cd /opt/phabricator
./bin/config set phabricator.timezone America/Los_Angeles
./bin/config set phabricator.show-prototypes true
./bin/config set storage.upload-size-limit 100M
./bin/config set metamta.mail-adapter PhabricatorMailImplementationPythonCLIAdapter
./bin/config set phpmailer.mailer smtp
./bin/config set phpmailer.smtp-host smtp.gmail.com
./bin/config set phpmailer.smtp-port 465
./bin/config set phpmailer.smtp-protocol ssl
./bin/config set pygments.enabled true
./bin/config set config.ignore-issues '{"mysql.ft_boolean_syntax":true, "mysql.ft_stopword_file": true, "daemons.need-restarting": true, "mysql.max_allowed_packet": true, "large-files": true}'
./bin/config set environment.append-paths '["/usr/lib/git-core/"]'