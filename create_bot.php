#!/usr/bin/env php
<?php
/**
Copyright 2015 Google Inc. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

$root = dirname(dirname(dirname(__FILE__)));
require_once $root.'/scripts/__init_script__.php';

if ($argc !== 4) {
  echo "usage: create_bot.php <username> <email> <realname>\n";
  exit(1);
}

$table = new PhabricatorUser();
$any_user = queryfx_one(
  $table->establishConnection('r'),
  'SELECT * FROM %T LIMIT 1',
  $table->getTableName());
$is_first_user = (!$any_user);

if ($is_first_user) {
  echo "You must first create an admin user before being able to create a system agent.\n";
  exit(1);
}

$username = $argv[1];
$email = $argv[2];
$realname = $argv[3];

if (!PhabricatorUser::validateUsername($username)) {
  $valid = PhabricatorUser::describeValidUsername();
  echo "The username '{$username}' is invalid. {$valid}\n";
  exit(1);
}

$existing_user = id(new PhabricatorUser())->loadOneWhere(
  'username = %s',
  $username);
if ($existing_user) {
  throw new Exception(
    "There is already a user with the username '{$username}'!");
}

$existing_email = id(new PhabricatorUserEmail())->loadOneWhere(
  'address = %s',
  $email);
if ($existing_email) {
  throw new Exception(
    "There is already a user with the email '{$email}'!");
}

$user_object = new PhabricatorUser();
$user_object->setUsername($username);
$user_object->setRealname($realname);
$user_object->setIsApproved(1);
$user_object->openTransaction();

$email_object = id(new PhabricatorUserEmail())
  ->setAddress($email)
  ->setIsVerified(1);

$editor = new PhabricatorUserEditor();
$editor->setActor($user_object);
$editor->createNewUser($user_object, $email_object);
$editor->makeSystemAgentUser($user_object, true);

$user_object->saveTransaction();
