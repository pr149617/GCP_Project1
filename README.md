# Terraform Google Cloud Project

This project uses Terraform to create and manage resources in Google Cloud Platform (GCP). The Terraform configuration sets up a VPC, a subnet, firewall rules, an instance template, auto-healing instance groups, a health check, a backend service, and URL maps for a web application. The application also includes a health check at `/healthz.html`.

![Screenshot Description](GCP_Project1/diagram.png)

## Resources

### 1. **google_compute_network** - `vpc-t`
   - Creates a Virtual Private Cloud (VPC) network named `vpc-t`.
   - The network has `auto_create_subnetworks` set to `false` to manually create subnets.

### 2. **google_compute_subnetwork** - `devsubnet`
   - Creates a subnet (`devsubnet`) within the previously created VPC (`vpc-t`).
   - It assigns the subnet a CIDR range of `172.16.0.0/24` and places it in the `asia-south1` region.

### 3. **google_compute_firewall** - `allowmultiport`
   - Configures firewall rules to allow inbound traffic on ports `22` (SSH), `80` (HTTP), `8080` (HTTP alternative), and `3389` (RDP).
   - The firewall rule applies to the `vpc-t` network with source IP range `0.0.0.0/0`.

### 4. **google_compute_instance_template** - `vmtemplate`
   - Defines an instance template to launch virtual machine instances with `e2-medium` machine type, a 100 GB boot disk, and the `ubuntu-2004-lts` image.
   - Includes a startup script to install Apache, create a `healthz.html` page, and start the Apache service.

### 5. **google_compute_instance_group_manager** - `intancegroup`
   - Manages an instance group (`instancegroup`) in zone `asia-south1-c`, launching instances based on the `vmtemplate` instance template.
   - Includes health-check auto-healing policies with an initial delay of 300 seconds and a target size of 2 instances.

### 6. **google_compute_health_check** - `autohealing`
   - Configures a health check named `autohealing-health-check` with an HTTP request path of `/healthz` on port `80`.
   - If the health check fails multiple times (based on defined thresholds), the affected instances will be recreated automatically.

### 7. **google_compute_backend_service** - `backend_service`
   - Creates a backend service (`http-backend-service`) that uses the `customhttp` named port, ensuring the health checks are applied.
   - Connects to the instance group created in `intancegroup`.

### 8. **google_compute_url_map** - `url_map`
   - Defines a URL map (`http-url-map`) to route HTTP traffic to the `backend_service`. This URL map serves as the central routing mechanism for incoming requests.

### 9. **google_compute_target_http_proxy** - `http_proxy`
   - Creates a target HTTP proxy (`http-target-proxy`) to forward HTTP requests to the URL map, ensuring that traffic is properly routed to the backend service.

### 10. **google_compute_global_forwarding_rule** - `http_forwarding_rule`
   - Configures a global forwarding rule to route incoming HTTP traffic on port `80` to the `http-target-proxy`.
   - This rule ensures that the application is accessible via the global HTTP endpoint.

## How to Use

1. Ensure you have the necessary credentials and permissions for Google Cloud.
2. Customize the `svckey.json` and other values as needed for your project.
3. Run the following Terraform commands:
   ```bash
   terraform init
   terraform plan
   terraform apply
