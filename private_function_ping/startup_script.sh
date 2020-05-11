#!/bin/bash

# Install Updates and Apache
echo "Updating packages"
apt-get update
apt-get install -y apache2

# Set HTML as start page
echo "Setting startpage"
cat <<EOF > /var/www/html/index.xml
<status><service name="service_one" status="HEALTHY" /><service name="service_two" status="DEGRADED" /></status>
EOF

# Restart Apache
/etc/init.d/apache2 restart