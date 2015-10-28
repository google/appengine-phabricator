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

# This file defines a supervisord event listener which checks for shutdown requests.
#
# This works by:
# 1. Configuring Apache to log requests to ^/_ah/stop to a special log file.
# 2. Polling to see if that log file exists and is non-empty.
#
# After seeing such a request, this script shuts down supervisord

# We must output "READY" before supervisord will send events
echo "READY"

# Read in the next event header
read

# We must output "RESULT 2\nOK" to let supervisord know the event has been accepted
echo "RESULT 2"
echo "OK"
while true; do
	if [ -s "/usr/local/apache/logs/shutdown.log" ]; then
		# Note that the final custom logs written before the VM is shutdown might not
		# be copied to logs viewer, as there is a race condition between the logs being
		# written and the fluentd logger shutting down.
		echo "Shutting down" >> /var/log/app_engine/custom_logs/phd_stop.log
		/opt/phabricator/bin/phd stop >> /var/log/app_engine/custom_logs/phd_stop.log
	fi
done
