#!/bin/bash

if [ -z "$DOMAIN" ]; then
    echo "DOMAIN environment variable is not set."
    exit 1
fi

# Use Certbot to obtain SSL certificates without interactive prompts
certbot certonly --nginx -d $DOMAIN --agree-tos --email your-email@example.com --non-interactive

# Replace the placeholder in the Nginx configuration template with the actual domain
sed "s/DOMAIN_NAME/$DOMAIN/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Reload Nginx to apply the new configuration
nginx -s reload

# Start Nginx in the foreground
nginx -g 'daemon off;'
