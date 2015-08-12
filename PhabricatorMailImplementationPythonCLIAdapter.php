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

/**
 * Mail adapter that uses Google App Engine Python API to deliver email.
 */
final class PhabricatorMailImplementationPythonCLIAdapter
  extends PhabricatorMailImplementationAdapter {

  private $params = array();

  public function setFrom($email, $name = '') {
    $this->params['from'] = $email;
    $this->params['from-name'] = $name;
    return $this;
  }

  public function addReplyTo($email, $name = '') {
    if (empty($this->params['reply-to'])) {
      $this->params['reply-to'] = array();
    }
    $this->params['reply-to'][] = array(
      'email' => $email,
      'name'  => $name,
    );
    return $this;
  }

  public function addTos(array $emails) {
    foreach ($emails as $email) {
      $this->params['tos'][] = $email;
    }
    return $this;
  }

  public function addCCs(array $emails) {
    foreach ($emails as $email) {
      $this->params['ccs'][] = $email;
    }
    return $this;
  }

  public function addAttachment($data, $filename, $mimetype) {
    if (empty($this->params['files'])) {
      $this->params['files'] = array();
    }
    $this->params['files'][$filename] = $data;
  }

  public function addHeader($header_name, $header_value) {
    $this->params['headers'][] = array($header_name, $header_value);
    return $this;
  }

  public function setBody($body) {
    $this->params['body'] = $body;
    return $this;
  }

  public function setHTMLBody($body) {
    $this->params['html-body'] = $body;
    return $this;
  }


  public function setSubject($subject) {
    $this->params['subject'] = $subject;
    return $this;
  }

  public function supportsMessageIDHeader() {
    return false;
  }

/**
 * The method that calls the Python CLI to do the actual mail sending.
 * All user provided arguments are escaped so as to account for any special characters within it.
 */
  public function send() {
    $email_subject =  escapeshellarg($this->params['subject']);
    $email_body = escapeshellarg($this->params['body']);
    $email_tos =  escapeshellarg(json_encode($this->params['tos']));
    $email_ccs = escapeshellarg(null);
		if(array_key_exists('ccs', $this->params)) {
        $email_ccs = escapeshellarg(json_encode($this->params['ccs']));
		}

    $cmd = "python /opt/send_mail.py --to $email_tos --email_subject $email_subject --email_body $email_body --cc $email_ccs";
    echo $cmd;
    exec($cmd);
    return true;
  }

}
