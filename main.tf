provider "google" {
    credentials = file("/path/svckey.json")
    project = "GCP-PRoject-ID"
    region = "asia-south1"
    

  
}
resource "google_compute_network" "vpc-t" {
    name = "vpc-t"
     auto_create_subnetworks = "false"
     
  
}
resource "google_compute_subnetwork" "devsubnet" {
  name = "devsubnet"
  network = google_compute_network.vpc-t.id
  ip_cidr_range = "172.16.0.0/24"
  region = "asia-south1"
}

resource "google_compute_firewall" "allowmultiport" {
    name = "allow-multiport"
    network = google_compute_network.vpc-t.name
    allow {
      protocol = "tcp"
      ports = ["22","80","8080","3389","8888"]
    
    }

    source_ranges = ["0.0.0.0/0"]
  
}


resource "google_compute_instance_template" "vmtemplate" {
  name         = "vmtemplate"
  machine_type = "e2-medium"

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    auto_delete  = true
    disk_size_gb = 100
    boot         = true
  }

  network_interface {
    network = google_compute_network.vpc-t.name
    subnetwork = google_compute_subnetwork.devsubnet.name
    access_config {
      
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Update package repository and install Apache
    sudo apt-get update
    sudo apt-get install -y apache2

    # Create healthz.html endpoint
    sudo echo "OK" | sudo tee /var/www/html/healthz.html

    # Start Apache service
    sudo systemctl enable apache2
    sudo systemctl start apache2
  EOT

  
}


resource "google_compute_instance_group_manager" "intancegroup" {
  name = "instancegroup"
  base_instance_name = "dev"
  zone = "asia-south1-c"
  version {
    instance_template = google_compute_instance_template.vmtemplate.id
  }
    
  target_size  = 2


  named_port {
    name = "customhttp"
    port = 8888
  }
   auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }

}

resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 10
  timeout_sec         = 10
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    request_path = "/healthz"
    port         = "80"
  }
}

resource "google_compute_backend_service" "backend_service" { //Backend service
  name                  = "http-backend-service"
  port_name             = "customhttp" # Match the named port in instance group
  protocol              = "HTTP"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.autohealing.id]

  backend {
    group = google_compute_instance_group_manager.intancegroup.instance_group
  }
}
resource "google_compute_url_map" "url_map" { // Create the URL Map
  name          = "http-url-map"
  default_service = google_compute_backend_service.backend_service.id
}
resource "google_compute_target_http_proxy" "http_proxy" { //Create the Target HTTP Proxy
  name   = "http-target-proxy"
  url_map = google_compute_url_map.url_map.id
}
resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name       = "http-global-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"

  # If you want a static external IP, create and reference one:
  # ip_address = google_compute_global_address.lb_ip.address

  # Use an ephemeral IP by leaving `ip_address` undefined
}
