# computo.tf
# Las dos maquinas. La diferencia entre estar publicada y no estarlo son
# tres lineas: la subred, el bloque access_config y la etiqueta de red.

# Maquina de datos. Vive en la subred privada y NO declara access_config,
# asi que no tiene IP externa y nadie puede iniciar una conexion hacia ella.
resource "google_compute_instance" "datos" {
  name         = "${var.prefijo}-datos"
  machine_type = var.tipo_maquina
  zone         = var.zona
  tags         = ["servidor-datos"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.privada.id
    # Sin access_config: no hay IP publica. Esa ausencia ES la medida de
    # seguridad. No hay regla que revisar ni puerto que cerrar.
  }

  metadata_startup_script = file("${path.module}/arranque-datos.sh")

  # Dependencia real que no aparece en ninguna referencia: sin NAT, esta
  # maquina no tiene salida a internet y el apt-get del arranque falla.
  # Este es el caso exacto para el que existe depends_on.
  depends_on = [google_compute_router_nat.nat]
}

# Maquina de aplicacion. Vive en la subred publica y si tiene IP externa.
resource "google_compute_instance" "app" {
  name         = "${var.prefijo}-app"
  machine_type = var.tipo_maquina
  zone         = var.zona
  tags         = ["servidor-web"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.publica.id
    # Un bloque vacio aqui otorga una IP publica efimera.
    access_config {}
  }

  # templatefile inyecta la IP interna de la maquina de datos dentro del
  # script. Esa referencia crea la dependencia en el grafo: Terraform crea
  # primero la maquina de datos y despues esta. No hace falta depends_on.
  metadata_startup_script = templatefile("${path.module}/arranque-app.sh", {
    ip_datos = google_compute_instance.datos.network_interface[0].network_ip
  })
}
