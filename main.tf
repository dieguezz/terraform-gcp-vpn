# --- Configuración del Proveedor y Variables ---

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "El ID de proyecto de GCP."
  type        = string
}

variable "region" {
  description = "La región de GCP para desplegar los recursos."
  type        = string
  default     = "europe-southwest1"
}

variable "zone" {
  description = "La zona de GCP para la VM."
  type        = string
  default     = "europe-southwest1-a"
}

# --- Red (VPC, Subnet, Firewall) ---

resource "google_compute_network" "vpn_vpc" {
  name                    = "vpn-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpn_subnet" {
  name          = "vpn-subnet"
  ip_cidr_range = "10.10.10.0/24"
  region        = var.region
  network       = google_compute_network.vpn_vpc.id
}

resource "google_compute_firewall" "allow_openvpn" {
  name          = "allow-openvpn-access"
  network       = google_compute_network.vpn_vpc.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["openvpn-server"]

  allow {
    protocol = "udp"
    ports    = ["1194"]
  }
  allow {
    protocol = "tcp"
    ports    = ["443", "943"] # Puertos para la consola web de OpenVPN AS
  }
}

# REGLA DE FIREWALL PARA SSH A TRAVÉS DE IAP - MÁS SEGURA Y ROBUSTA
resource "google_compute_firewall" "allow_ssh_via_iap" {
  name          = "allow-ssh-via-iap"
  network       = google_compute_network.vpn_vpc.name
  direction     = "INGRESS"
  # Este rango de IPs pertenece al servicio IAP de Google.
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["openvpn-server"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}


# --- Cloud NAT (IP de Salida Estática) ---
resource "google_compute_address" "nat_static_ip" {
  name   = "vpn-nat-static-ip"
  region = var.region
}
resource "google_compute_router" "vpn_router" {
  name    = "vpn-router"
  network = google_compute_network.vpn_vpc.id
  region  = var.region
}
resource "google_compute_router_nat" "vpn_nat" {
  name                               = "vpn-nat-gateway"
  router                             = google_compute_router.vpn_router.name
  region                             = google_compute_router.vpn_router.region
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
  subnetwork {
    name                    = google_compute_subnetwork.vpn_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.nat_static_ip.self_link]
}

# --- Instancia de Compute Engine para OpenVPN ---
resource "google_compute_instance" "openvpn_server" {
  name         = "openvpn-server-instance"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["openvpn-server"]

  boot_disk {
    initialize_params {
      # Usamos la imagen de openvpn de un marketplace pero esto deberiamos sustituirlo por un ubuntu y configurarlo nosotros para no tener que pagar licencias. De momento el tier gratuito nos vale
      image = "projects/openvpn-access-server-200800/global/images/aspub2143-20250711"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpn_subnet.id
    access_config {}
  }

  can_ip_forward = true
}

# --- Outputs (Resultados) ---

output "openvpn_admin_ui" {
  description = "URL de la consola de administración de OpenVPN. Usa el usuario 'openvpn' y la contraseña que verás en los logs de la instancia."
  value       = "https://${google_compute_instance.openvpn_server.network_interface[0].access_config[0].nat_ip}:943/admin"
}

output "openvpn_client_ui" {
  description = "URL para que los usuarios descarguen el cliente VPN."
  value       = "https://${google_compute_instance.openvpn_server.network_interface[0].access_config[0].nat_ip}:943"
}

output "instance_initial_password_command" {
  description = "Obtener la contraseña inicial del usuario 'openvpn'."
  value       = "gcloud compute instances get-serial-port-output ${google_compute_instance.openvpn_server.name} --zone ${google_compute_instance.openvpn_server.zone} | grep 'Initial password'"
}

output "egress_static_ip" {
  description = "La IP de salida estática para la instancia OpenVPN."
  value       = google_compute_address.nat_static_ip.address
}