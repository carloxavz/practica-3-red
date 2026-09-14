#!/bin/bash
apt-get update -y
apt-get install -y nginx
INTERNA=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
cat > /var/www/html/index.html <<HTML
<h1>HOLA CARLOS AVENDANO</h1>
<p>Servidor de aplicación. IP interna: $INTERNA</p>
HTML
