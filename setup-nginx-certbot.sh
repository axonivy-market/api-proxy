#!/bin/bash

set -e

DOMAIN="apitest.server.ivy-cloud.com"
EMAIL="hcmc-octopus@axonactive.com"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update package list
echo "Updating package list..."
sudo apt update

# Install Nginx if not already installed
if ! command_exists nginx; then
    echo "Installing Nginx..."
    sudo apt install -y nginx
else
    echo "Nginx is already installed."
fi

# Install Certbot and Nginx plugin
echo "Installing Certbot and Nginx plugin..."
sudo apt install -y certbot python3-certbot-nginx

# Copy nginx.conf.default to nginx.conf
if [ -f nginx.conf.default ]; then
    echo "Copying nginx.conf.default to nginx.conf..."
    sudo cp nginx.conf.default /etc/nginx/nginx.conf
else
    echo "nginx.conf.default file not found. Skipping copy."
fi

# Generate the Diffie-Hellman parameters required for the SSL configuration
echo "Generating Diffie-Hellman parameters..."
sudo openssl dhparam -out /etc/nginx/dhparam.pem 2048

# Restart Nginx to apply the new configuration
echo "Restarting Nginx..."
sudo systemctl restart nginx

# Set up SSL with Certbot
echo "Setting up SSL with Certbot..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

# Copy nginx.conf to /etc/nginx/nginx.conf and restart Nginx
if [ -f nginx.conf ]; then
    echo "Copying nginx.conf..."
    sudo cp nginx.conf /etc/nginx/nginx.conf
else
    echo "nginx.conf file not found. Skipping copy."
fi

echo "Restarting Nginx..."
sudo systemctl restart nginx

# Set up automatic renewal
echo "Setting up automatic SSL renewal..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

echo "Nginx installation, Certbot setup, and SSL configuration completed successfully!"
