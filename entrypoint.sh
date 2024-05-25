#!/bin/bash

if [ -z "$DOMAIN" ]; then
    echo "DOMAIN environment variable is not set."
    exit 1
fi

# Create necessary directories if they don't exist
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

# Check if the certificate already exists
if [ ! -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ] || [ ! -f /etc/letsencrypt/live/$DOMAIN/privkey.pem ]; then
    echo "Certificate does not exist, requesting a new one..."
    certbot certonly --nginx -d $DOMAIN --agree-tos --email bh419@protonmail.com --non-interactive -v
    CERTBOT_EXIT_CODE=$?

    if [ $CERTBOT_EXIT_CODE -ne 0 ]; then
        echo "Certbot failed with exit code $CERTBOT_EXIT_CODE"
        exit 1
    fi
else
    echo "Certificate already exists, skipping Certbot request."
fi

# Replace the placeholder in the Nginx configuration template with the actual domain
sed "s/DOMAIN_NAME/$DOMAIN/g" /etc/nginx/nginx.conf.template > /etc/nginx/sites-available/$DOMAIN.conf

# Create a symbolic link to the sites-enabled directory if it doesn't already exist
if [ ! -f /etc/nginx/sites-enabled/$DOMAIN.conf ]; then
    ln -s /etc/nginx/sites-available/$DOMAIN.conf /etc/nginx/sites-enabled/
fi

# Check if the main configuration includes the sites-enabled directory
if ! grep -q "include /etc/nginx/sites-enabled/*.conf;" /etc/nginx/nginx.conf; then
    sed -i '/http {/a \    include /etc/nginx/sites-enabled/*.conf;' /etc/nginx/nginx.conf
fi

# Test the Nginx configuration
nginx -t
NGINX_TEST_EXIT_CODE=$?

if [ $NGINX_TEST_EXIT_CODE -ne 0 ]; then
    echo "Nginx configuration test failed with exit code $NGINX_TEST_EXIT_CODE"
    exit 1
fi

# Stop Nginx to free up the ports
nginx -s stop

# Ensure certificates are present
if [ ! -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ] || [ ! -f /etc/letsencrypt/live/$DOMAIN/privkey.pem ]; then
    echo "Certificates not found for $DOMAIN"
    exit 1
fi

# Start Nginx in the foreground
nginx -g 'daemon off;'
