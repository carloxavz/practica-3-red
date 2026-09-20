#!/bin/bash
# Maquina de datos. Sin IP publica: todo el trafico de salida de este
# script (apt-get) viaja por el Cloud NAT.

apt-get update -y
apt-get install -y redis-server

# Redis solo escucha en localhost por defecto. Lo abrimos a la red porque
# la app lo consulta desde otra maquina. El aislamiento NO lo da Redis:
# lo dan la ausencia de IP publica y la regla de cortafuegos por etiqueta.
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf
sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf
systemctl restart redis-server

# Espera a que Redis acepte conexiones antes de escribir las claves.
for i in $(seq 1 30); do
  redis-cli ping > /dev/null 2>&1 && break
  sleep 1
done

INTERNA=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

redis-cli set inventario:articulos 1482
redis-cli set inventario:bodega "Cucuta - Norte de Santander"
redis-cli set origen "maquina de datos privada $INTERNA"
