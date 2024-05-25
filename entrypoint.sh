#!/bin/bash

if [ -z "$DOMAIN" ]; then
    echo "DOMAIN environment variable is not set."
    exit 1
fi

# Create necessary directories if they don't exist
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

# Use Certbot to obtain SSL certificates without interactive prompts
certbot certonly --nginx -d $DOMAIN --agree-tos --email valid-email@example.com --non-interactive

# Replace the placeholder in the Nginx configuration template with the actual domain
sed "s/DOMAIN_NAME/$DOMAIN/g" /etc/nginx/nginx.conf.template > /etc/nginx/sites-available/$DOMAIN.conf

# Create a symbolic link to the sites-enabled directory if it doesn't already exist
if [ ! -f /etc/nginx/sites-enabled/$DOMAIN.conf ]; then
    ln -s /etc/nginx/sites-available/$DOMAIN.conf /etc/nginx/sites-enabled/
fi

# Test the Nginx configuration
nginx -t

# Reload Nginx to apply the new configuration
nginx -s reload

# Start Nginx in the foreground
nginx -g 'daemon off;'
