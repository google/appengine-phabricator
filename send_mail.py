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

# Python CLI for sending email. Currently does not handle attachments
from google.appengine.api import mail
import click
import logging
import json
import os

'''The below statements are required because we are not using the standard python runtime
This will be fixed in the next launch but we have to live with it for now'''
from google.appengine.ext.vmruntime import vmconfig
from google.appengine.ext.vmruntime import vmstub
vmstub.Register(vmstub.VMStub(vmconfig.BuildVmAppengineEnvConfig().default_ticket))
vmstub.app_is_loaded = True

@click.command()
@click.option('--to', help='users to receive the email')
@click.option('--email_subject', help='email subject to be sent to users')
@click.option('--email_body', help='email body to be sent to users')
@click.option('--cc', help='cc users to receive the email')

def send_mail(to, email_subject, email_body, cc):
    application_id = os.environ.get('GAE_LONG_APP_ID')
    message = mail.EmailMessage(sender="noreply@phabricator.example.com", subject=email_subject)
    message.sender = "noreply@" + application_id + ".appspotmail.com"
    message.to = json.loads(to)
    message.body = email_body
    if cc:
      message.cc = json.loads(cc)
    message.send()

if __name__ == '__main__':
    send_mail()