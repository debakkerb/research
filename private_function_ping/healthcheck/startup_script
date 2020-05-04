#!/bin/bash

# Install Updates and Apache
echo "Updating packages"
apt-get update
apt-get install -y apache2

# Set HTML as start page
echo "Setting startpage"
cat <<EOF > /var/www/html/index.html
<html><body><h1>Hello World</h1>
<p>This page was created from a simple startup script.</p>
</body></html>
EOF

# Restart Apache
/etc/init.d/apache2 restart