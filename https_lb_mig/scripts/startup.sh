#!/usr/bin/env bash

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export PRIVATE_IP=$(curl -s -X GET -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
export HOST_NAME=$(curl -s -X GET -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
export ZONE=$(curl -s -X GET -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/zone")

apt-get update -y
apt-get upgrade -y
apt install apache2 -y

cat >/var/www/html/index.html <<EOL
<html>
  <head>
    <title>Load Balancer Test</title>
  </head>
  <body>
    <h1>Load Balancer Test</h1>
    <table>
      <tr>
        <td>Hostname</td>
        <td>${HOST_NAME}</td>
      </tr>
      <tr>
        <td>IP Address</td>
        <td>${PRIVATE_IP}</td>
      </tr>
      <tr>
        <td>Zone</td>
        <td>${ZONE}</td>
      </tr>
    </table>
  </body>
</html>
EOL
