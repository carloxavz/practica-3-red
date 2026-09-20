# red.tf
# La red y su direccionamiento: VPC, las dos subredes, y la salida a
# internet de la subred privada (Cloud Router + Cloud NAT).

# La VPC es global. En modo personalizado nace sin subredes.
resource "google_compute_network" "vpc" {
  name                    = "${var.prefijo}-vpc"
  auto_create_subnetworks = false
}

# Subred publica: aqui vive la aplicacion, que si tiene IP externa.
resource "google_compute_subnetwork" "publica" {
  name          = "${var.prefijo}-sub-publica"
  ip_cidr_range = var.cidr_publica
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Subred privada: aqui vive la maquina de datos. Ninguna maquina de esta
# subred declara access_config, asi que ninguna es alcanzable desde fuera.
resource "google_compute_subnetwork" "privada" {
  name          = "${var.prefijo}-sub-privada"
  ip_cidr_range = var.cidr_privada
  region        = var.region
  network       = google_compute_network.vpc.id
}

# El Cloud Router es el recurso al que se engancha el NAT. Por si solo no
# hace nada en esta topologia: existe porque el NAT lo exige.
resource "google_compute_router" "router" {
  name    = "${var.prefijo}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# Cloud NAT: traduce la IP interna de la maquina privada por una publica
# compartida, SOLO para el trafico que sale. Nadie de fuera puede iniciar
# una conexion hacia adentro porque no hay direccion a la que dirigirse.
resource "google_compute_router_nat" "nat" {
  name                   = "${var.prefijo}-nat"
  router                 = google_compute_router.router.name
  region                 = var.region
  nat_ip_allocate_option = "AUTO_ONLY"

  # Decision: el NAT se aplica UNICAMENTE a la subred privada.
  # La subred publica no lo necesita, porque sus maquinas ya tienen IP
  # externa propia. Usar ALL_SUBNETWORKS_ALL_IP_RANGES habria funcionado
  # igual, pero cobraria por trafico que no necesita traduccion.
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.privada.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
