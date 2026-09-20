# firewall.tf
# En una VPC nueva toda la entrada se deniega y toda la salida se permite.
# Las tres reglas son, por tanto, de entrada.

# 1. La aplicacion es publica: cualquiera en internet puede alcanzar el 80.
resource "google_compute_firewall" "app_http" {
  name    = "${var.prefijo}-permitir-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]    # es un servicio web publico
  target_tags   = ["servidor-web"] # aplica solo a la app, no a toda la VPC
}

# 2. SSH solo desde el rango por el que Google reenvia IAP, nunca desde
#    internet. Apunta a las DOS maquinas: es la unica forma de entrar a la
#    maquina de datos, que no tiene IP publica.
resource "google_compute_firewall" "ssh_iap" {
  name    = "${var.prefijo}-permitir-ssh-iap"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # 35.235.240.0/20 es el rango desde el que Google reenvia SSH
  # a traves de IAP. Es el unico origen autorizado para el 22.
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["servidor-web", "servidor-datos"]
}

# 3. Trafico interno app -> datos, unicamente en el puerto de Redis.
#    source_tags (no source_ranges) significa: solo desde maquinas que
#    lleven la etiqueta servidor-web. Otra maquina de la misma subred,
#    sin esa etiqueta, no llega al 6379 aunque este a un salto de distancia.
resource "google_compute_firewall" "app_a_datos" {
  name    = "${var.prefijo}-permitir-redis-interno"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_tags = ["servidor-web"]
  target_tags = ["servidor-datos"]
}
