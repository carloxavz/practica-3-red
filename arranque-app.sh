#!/bin/bash
# Maquina de aplicacion. La pagina es dinamica porque tiene que consultar
# a la maquina de datos en cada peticion: si esa consulta falla, la pagina
# devuelve 503 y no se sirve.
#
# La IP de la maquina de datos la inyecta Terraform con templatefile(),
# tomandola del recurso real. Nada esta escrito a mano aqui.

apt-get update -y
apt-get install -y nginx php-fpm php-redis redis-tools

# nginx no sabe ejecutar PHP por si solo: hay que pasarle las peticiones
# .php a php-fpm por su socket. El nombre del socket lleva la version,
# asi que lo detectamos en vez de suponerla.
SOCK=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -n 1)

cat > /etc/nginx/sites-available/default <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /var/www/html;
    index index.php;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:PHP_SOCK;
    }
}
NGINX

sed -i "s|PHP_SOCK|$SOCK|" /etc/nginx/sites-available/default
rm -f /var/www/html/index.nginx-debian.html /var/www/html/index.html

cat > /var/www/html/index.php <<'PHP'
<?php
// La IP interna de la maquina de datos, inyectada por Terraform.
$ip_datos = '${ip_datos}';

$redis = new Redis();

try {
    $redis->connect($ip_datos, 6379, 2.0);
    $articulos = $redis->get('inventario:articulos');
    $bodega    = $redis->get('inventario:bodega');
    $origen    = $redis->get('origen');

    if ($articulos === false) {
        throw new Exception('Redis respondio pero la clave no existe');
    }
} catch (Throwable $e) {
    // Sin la maquina de datos esta pagina NO se sirve. Ese es el requisito
    // de dependencia real: no es un adorno que se degrada, es un 503.
    http_response_code(503);
    header('Content-Type: text/plain; charset=utf-8');
    echo "503 Service Unavailable\n\n";
    echo "La maquina de datos (" . $ip_datos . ":6379) no responde.\n";
    echo "Esta pagina no se puede servir sin ella.\n\n";
    echo "Detalle: " . $e->getMessage() . "\n";
    exit;
}

$mi_ip = $_SERVER['SERVER_ADDR'];
?>
<!doctype html>
<html lang="es">
<head><meta charset="utf-8"><title>Practica 3</title></head>
<body style="font-family: sans-serif; max-width: 640px; margin: 40px auto;">

  <h1>CARLOS AVENDANO</h1>
  <p>Servidor de aplicacion. IP interna: <b><?= htmlspecialchars($mi_ip) ?></b></p>

  <hr>

  <h2>Dato traido de la maquina privada</h2>
  <ul>
    <li>Articulos en inventario: <b><?= htmlspecialchars($articulos) ?></b></li>
    <li>Bodega: <b><?= htmlspecialchars($bodega) ?></b></li>
  </ul>
  <p>Origen del dato: <?= htmlspecialchars($origen) ?></p>
  <p>Consultado por Redis en <?= htmlspecialchars($ip_datos) ?>:6379,
     por la red interna de la VPC. Esa maquina no tiene IP publica.</p>

</body>
</html>
PHP

PHPFPM=$(systemctl list-unit-files --no-legend 'php*-fpm.service' | awk '{print $1}' | head -n 1)
systemctl restart "$PHPFPM"

nginx -t && systemctl restart nginx
