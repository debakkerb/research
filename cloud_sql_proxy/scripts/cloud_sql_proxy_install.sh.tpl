#!/usr/bin/env bash
# Copyright 2020 Google LLC
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

set -eu

INTERNET_CONNECTION="$(ping -q -w1 -c1 google.com &>/dev/null && echo online || echo offline)"

if [ $INTERNET_CONNECTION == "offline" ]; then
  echo "Cloud SQL Proyx Startup - An active internet connection is required."
fi

echo "Cloud SQL Proyx Startup - Upgrading packages and installing wget"

sudo apt-get update -y
sudo apt-get install -y wget curl

if ! [ -e "/usr/sbin/google-fluentd" ]; then
  echo "SQL Proxy Startup - Installing GCP Logging agent"
  curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
  sudo bash add-logging-agent-repo.sh --also-install
fi

echo "Cloud SQL Proxy Startup - Downloading the Cloud SQL proxy script ..."

wget "https://storage.googleapis.com/cloudsql-proxy/${cloud_sql_proxy_version}/cloud_sql_proxy.linux.amd64" -O cloud_sql_proxy
chmod +x cloud_sql_proxy
mv cloud_sql_proxy /usr/local/bin

echo "Cloud SQL Proyx Startup - Creating system service to load the Cloud SQL script automatically in the background."

sudo mkdir /var/run/cloud-sql-proxy
sudo mkdir /var/local/cloud-sql-proxy

sudo chown root:root /var/run/cloud-sql-proxy
sudo chown root:root /var/local/cloud-sql-proxy

cat <<EOT >> /lib/systemd/system/cloud-sql-proxy.service
[Install]
WantedBy=multi-user.target

[Unit]
Description=Google Cloud Compute Engine SQL Proxy
Requires=networking.service
After=networking.service

[Service]
Type=simple
WorkingDirectory=/usr/local/bin
ExecStart=/usr/local/bin/cloud_sql_proxy -dir=/var/run/cloud-sql-proxy -instances=${instance_connection_name}=tcp:0.0.0.0:5432 -structured_logs -log_debug_stdout=true
Restart=always
StandardOutput=journal
User=root
EOT

echo "Cloud SQL Proyx Startup - Starting the Cloud SQL Proxy service"

sudo systemctl daemon-reload
sudo systemctl start cloud-sql-proxy

echo "Cloud SQL Proyx Startup - Startup script Cloud SQL Proxy finished."
