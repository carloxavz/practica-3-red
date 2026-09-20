# outputs.tf

output "red" {
  value       = google_compute_network.vpc.name
  description = "Nombre de la VPC creada"
}

output "subred_publica" {
  value       = google_compute_subnetwork.publica.self_link
  description = "Identificador completo de la subred de aplicacion"
}

output "subred_privada" {
  value       = google_compute_subnetwork.privada.self_link
  description = "Identificador completo de la subred de datos"
}

output "ip_publica_app" {
  value       = google_compute_instance.app.network_interface[0].access_config[0].nat_ip
  description = "IP publica efimera de la aplicacion. Cambia en cada apply"
}

output "ip_interna_app" {
  value       = google_compute_instance.app.network_interface[0].network_ip
  description = "IP interna de la aplicacion, dentro de la subred publica"
}

output "ip_interna_datos" {
  value       = google_compute_instance.datos.network_interface[0].network_ip
  description = "IP interna de la maquina de datos. Es su unica direccion"
}
