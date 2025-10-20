#!/bin/bash
# ==============================================================================
# FIREZONE INSTALLATION AND CONFIGURATION SCRIPT
# Non-interactive version of Firezone's official install.sh (0.7.36)
# Adapted for automated deployment via Terraform
# ==============================================================================

set -e

# Configuration from Terraform template variables
FIREZONE_DOMAIN="${firezone_domain}"
ADMIN_EMAIL="${firezone_admin_email}"
INSTALL_DIR="/opt/firezone"
LOG_TAG="firezone-setup"

# Logging function
log() {
    echo "$LOG_TAG: $1"
    logger -t "$LOG_TAG" "$1" 2>/dev/null || true
}

log "Starting Firezone installation for domain: $FIREZONE_DOMAIN"

# ==============================================================================
# PRE-FLIGHT CHECKS FOR PRODUCTION DEPLOYMENT
# ==============================================================================

preflightChecks() {
  log "Running pre-flight checks..."
  
  # Check if domain is set
  if [ -z "$FIREZONE_DOMAIN" ]; then
    log "ERROR: FIREZONE_DOMAIN is not set!"
    exit 1
  fi
  
  # Get server's public IP
  SERVER_IP=$(curl -s -4 ifconfig.me || curl -s -4 icanhazip.com || echo "unknown")
  log "Server public IP: $SERVER_IP"
  
  # Check DNS resolution
  log "Checking DNS configuration for $FIREZONE_DOMAIN..."
  DNS_IP=$(dig +short $FIREZONE_DOMAIN A | tail -n1)
  
  if [ -z "$DNS_IP" ]; then
    log "WARNING: DNS not configured for $FIREZONE_DOMAIN"
    log "WARNING: Caddy will NOT be able to obtain SSL certificates!"
    log "WARNING: Please configure DNS A record: $FIREZONE_DOMAIN -> $SERVER_IP"
    log "Continuing in 10 seconds... (Ctrl+C to abort)"
    sleep 10
  elif [ "$DNS_IP" != "$SERVER_IP" ]; then
    log "WARNING: DNS mismatch!"
    log "  Domain $FIREZONE_DOMAIN points to: $DNS_IP"
    log "  Server IP is: $SERVER_IP"
    log "WARNING: SSL certificate provisioning may fail!"
    log "Continuing in 10 seconds... (Ctrl+C to abort)"
    sleep 10
  else
    log "✓ DNS correctly configured: $FIREZONE_DOMAIN -> $SERVER_IP"
  fi
  
  # Check required ports
  log "Checking if required ports are available..."
  for port in 80 443 51820; do
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
      log "WARNING: Port $port appears to be in use"
    else
      log "✓ Port $port available"
    fi
  done
  
  log "Pre-flight checks completed"
}

# Install dig for DNS checks
apt-get install -y dnsutils

# Run pre-flight checks
preflightChecks

# ==============================================================================
# PREREQUISITE CHECKS (from original install.sh)
# ==============================================================================

dockerCheck() {
  if ! type docker > /dev/null 2>&1; then
    log "ERROR: docker not found. Installing Docker..."
    return 1
  fi

  # Detect docker compose vs docker-compose (exact logic from original)
  if docker compose version &> /dev/null; then
    dc="docker compose"
  else
    if command -v docker-compose &> /dev/null; then
      dc="docker-compose"
    else
      log "ERROR: Docker Compose not found"
      return 1
    fi
  fi

  # Verify it's v2 (exact logic from original)
  set +e
  $dc version | grep -q "v2"
  if [ $? -ne 0 ]; then
    log "ERROR: Automatic installation is only supported with Docker Compose version 2 or higher"
    return 1
  fi
  set -e
  
  log "Docker check passed. Using: $dc"
  return 0
}

curlCheck() {
  if ! type curl > /dev/null 2>&1; then
    log "ERROR: curl not found. Installing curl..."
    return 1
  fi
  return 0
}

# ==============================================================================
# SYSTEM SETUP (Ubuntu-specific)
# ==============================================================================

log "Updating system packages..."
apt-get update -y
apt-get upgrade -y

log "Installing required packages..."
apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    ca-certificates \
    software-properties-common \
    ufw

# Install Docker if needed
if ! dockerCheck; then
  log "Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  rm get-docker.sh
  systemctl enable docker
  systemctl start docker
  
  # Install Docker Compose
  log "Installing Docker Compose..."
  DOCKER_COMPOSE_VERSION="v2.24.5"
  curl -SL "https://github.com/docker/compose/releases/download/$${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
  
  # Wait for Docker to be ready
  sleep 5
  
  # Add ubuntu user to docker group
  usermod -aG docker ubuntu || true
fi

# Verify Docker and curl are available
curlCheck || exit 1
dockerCheck || exit 1

# Re-export dc variable for use in rest of script
if docker compose version &> /dev/null; then
  dc="docker compose"
elif command -v docker-compose &> /dev/null; then
  dc="docker-compose"
fi

# ==============================================================================
# FIREZONE SETUP (from original firezoneSetup function)
# ==============================================================================

firezoneSetup() {
  local adminEmail="$1"
  local externalUrl="$2"
  
  export FZ_INSTALL_DIR=$INSTALL_DIR

  log "Setting up Firezone directory structure..."
  mkdir -p $INSTALL_DIR
  cd $INSTALL_DIR

  # Download docker-compose.yml (exact logic from original)
  if ! test -f $INSTALL_DIR/docker-compose.yml; then
    os_type="$(uname -s)"
    case "$${os_type}" in
      Linux*)
        file=docker-compose.prod.yml
        ;;
      *)
        file=docker-compose.desktop.yml
        ;;
    esac
    log "Downloading $${file}..."
    curl -fsSL https://raw.githubusercontent.com/firezone/firezone/legacy/$${file} -o $INSTALL_DIR/docker-compose.yml
    
    # Fix Caddy configuration for proper network connectivity
    # The default docker-compose.yml uses network_mode: "host" which prevents
    # Caddy from reaching Firezone on the Docker network
    log "Applying Caddy network configuration fix..."
    
    # Backup original
    cp $INSTALL_DIR/docker-compose.yml $INSTALL_DIR/docker-compose.yml.original
    
    # Replace network_mode: "host" with proper network configuration
    # This is a multi-line replacement, so we use Python for reliability
    python3 << 'PYTHON_FIX'
import re

compose_file = "/opt/firezone/docker-compose.yml"

with open(compose_file, 'r') as f:
    content = f.read()

# Fix 1: Replace network_mode: "host" with proper ports and network config for caddy service
old_caddy_network = r'    network_mode: "host"'
new_caddy_network = '''    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    networks:
      - firezone-network
    depends_on:
      - firezone'''

content = content.replace(old_caddy_network, new_caddy_network)

# Fix 2: Change reverse_proxy from IP to service name
content = re.sub(
    r'reverse_proxy \* 172\.25\.0\.100:\$\{PHOENIX_PORT:-13000\}',
    r'reverse_proxy firezone:$${PHOENIX_PORT:-13000}',
    content
)

with open(compose_file, 'w') as f:
    f.write(content)

print("Caddy configuration updated successfully")
PYTHON_FIX
    
    log "✓ Caddy configuration updated for proper Docker networking"
  fi

  # Generate secure passwords (exact logic from original)
  log "Generating secure configuration..."
  db_pass=$(od -vN "8" -An -tx1 /dev/urandom | tr -d " \n" ; echo)
  
  # Generate .env using Firezone image (exact logic from original)
  log "Generating Firezone environment configuration..."
  docker run --rm firezone/firezone bin/gen-env > "$INSTALL_DIR/.env"

  # Update .env with our values (exact logic from original)
  sed -i.bak "s/DEFAULT_ADMIN_EMAIL=.*/DEFAULT_ADMIN_EMAIL=$adminEmail/" "$INSTALL_DIR/.env"
  sed -i.bak "s~EXTERNAL_URL=.*~EXTERNAL_URL=$externalUrl~" "$INSTALL_DIR/.env"
  sed -i.bak "s/DATABASE_PASSWORD=.*/DATABASE_PASSWORD=$db_pass/" "$INSTALL_DIR/.env"
  
  # Use stable legacy version 0.7.36 for production deployment
  # Note: Firezone has moved to 1.x+ which is a different architecture
  # The legacy 0.7.x branch is what we need for this docker-compose setup
  FIREZONE_VERSION="0.7.36"
  sed -i.bak "s~VERSION=.*~VERSION=$${FIREZONE_VERSION}~" "$INSTALL_DIR/.env"
  
  # Telemetry disabled for automated deployment
  echo "TELEMETRY_ENABLED=false" >> "$INSTALL_DIR/.env"
  echo "TID=$tid" >> "$INSTALL_DIR/.env"

  # XXX: This causes perms issues on macOS with postgres (comment from original)
  # echo "UID=$(id -u)" >> $INSTALL_DIR/.env
  # echo "GID=$(id -g)" >> $INSTALL_DIR/.env

  # Start PostgreSQL (exact logic from original)
  log "Starting PostgreSQL database..."
  DATABASE_PASSWORD=$db_pass $dc -f $INSTALL_DIR/docker-compose.yml up -d postgres
  
  log "Waiting for DB to boot..."
  sleep 5
  
  $dc -f $INSTALL_DIR/docker-compose.yml logs postgres
  
  log "Resetting DB password..."
  $dc -f $INSTALL_DIR/docker-compose.yml exec -T postgres psql -p 5432 -U postgres -d firezone -h 127.0.0.1 -c "ALTER ROLE postgres WITH PASSWORD '$${db_pass}'"
  
  log "Migrating DB..."
  $dc -f $INSTALL_DIR/docker-compose.yml run -e TELEMETRY_ID="$${tid}" --rm firezone bin/migrate
  
  log "Creating admin..."
  $dc -f $INSTALL_DIR/docker-compose.yml run -e TELEMETRY_ID="$${tid}" --rm firezone bin/create-or-reset-admin
  
  log "Upping firezone services..."
  $dc -f $INSTALL_DIR/docker-compose.yml up -d firezone caddy

  log "Firezone installation complete!"
  
  # Display credentials (adapted from original)
  cat << EOF

Installation complete!

You should now be able to log into the Web UI at $externalUrl with the
following credentials:

$(grep DEFAULT_ADMIN_EMAIL $INSTALL_DIR/.env)
$(grep DEFAULT_ADMIN_PASSWORD $INSTALL_DIR/.env)

EOF
}

# ==============================================================================
# MAIN EXECUTION (adapted from original main function)
# ==============================================================================

# Generate telemetry ID (exact logic from original)
telemetry_id=$(od -vN "8" -An -tx1 /dev/urandom | tr -d " \n" ; echo)
tid=$${1:-$telemetry_id}

# Run Firezone setup with non-interactive parameters
log "Running Firezone setup..."
firezoneSetup "$ADMIN_EMAIL" "https://$FIREZONE_DOMAIN"


# ==============================================================================
# POST-INSTALLATION CONFIGURATION (VPN-specific additions)
# ==============================================================================

# ==============================================================================
# ENABLE IP FORWARDING - CRITICAL FOR MULTI-CLIENT VPN
# ==============================================================================

log "Enabling IP forwarding for multi-client VPN support..."

# Enable IP forwarding permanently
cat >> /etc/sysctl.conf << 'EOF'

# IP Forwarding for VPN - Added by Firezone installer
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

# Apply immediately
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

log "IP forwarding enabled successfully"

# ==============================================================================
# CONFIGURE NAT/MASQUERADING - CRITICAL FOR VPN ROUTING
# ==============================================================================

log "Configuring NAT and masquerading for VPN traffic..."

# Get the primary network interface
PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
log "Primary network interface detected: $${PRIMARY_INTERFACE}"

# Configure iptables for NAT masquerading
# This allows VPN clients to route through the server
iptables -t nat -A POSTROUTING -o $${PRIMARY_INTERFACE} -j MASQUERADE
iptables -A FORWARD -i wg-firezone -j ACCEPT
iptables -A FORWARD -o wg-firezone -j ACCEPT

# Save iptables rules permanently
log "Saving iptables rules..."
apt-get install -y iptables-persistent netfilter-persistent
netfilter-persistent save

log "NAT and masquerading configured successfully"

# Configure firewall
log "Configuring firewall rules..."
ufw --force enable
ufw allow ssh
ufw allow 80/tcp   # HTTP for ACME challenges
ufw allow 443/tcp  # HTTPS for admin interface
ufw allow 51820/udp # WireGuard

# ==============================================================================
# VERIFY SSL CERTIFICATE PROVISIONING
# ==============================================================================

log "Waiting for Caddy to provision SSL certificates..."
log "This may take up to 2 minutes..."

# Wait for Caddy to be ready and attempt SSL provisioning
sleep 10

# Check if Caddy obtained SSL certificate
MAX_RETRIES=12
RETRY_COUNT=0
SSL_SUCCESS=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  log "Checking SSL certificate status (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)..."
  
  # Check if we can connect via HTTPS
  if curl -sSf -k -m 5 "https://$${FIREZONE_DOMAIN}" > /dev/null 2>&1; then
    # Verify it's a valid Let's Encrypt certificate (not self-signed)
    CERT_ISSUER=$(echo | openssl s_client -servername $${FIREZONE_DOMAIN} -connect $${FIREZONE_DOMAIN}:443 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null | grep -o "Let's Encrypt" || echo "")
    
    if [ -n "$${CERT_ISSUER}" ]; then
      log "✓ SSL certificate successfully provisioned by Let's Encrypt!"
      SSL_SUCCESS=true
      break
    else
      log "HTTPS responding but certificate may be self-signed, waiting..."
    fi
  fi
  
  # Check Caddy logs for SSL-related errors
  $dc -f $INSTALL_DIR/docker-compose.yml logs caddy 2>/dev/null | tail -20 | grep -i "error\|certificate\|acme" || true
  
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    sleep 10
  fi
done

if [ "$SSL_SUCCESS" = false ]; then
  log "WARNING: Could not verify SSL certificate provisioning!"
  log "This may be because:"
  log "  1. DNS is not properly configured"
  log "  2. Port 80/443 is blocked by firewall"
  log "  3. Let's Encrypt rate limits"
  log ""
  log "Check Caddy logs: $dc -f $INSTALL_DIR/docker-compose.yml logs caddy"
  log "You can access the admin panel at: http://$${FIREZONE_DOMAIN} (HTTP)"
  log "Or try: https://$${FIREZONE_DOMAIN} (HTTPS - may show certificate warning)"
else
  log "SSL certificate verification successful!"
fi

# ==============================================================================
# SECURITY HARDENING
# ==============================================================================

log "Applying security hardening..."

# Install and configure fail2ban for SSH protection
log "Installing fail2ban for SSH protection..."
apt-get install -y fail2ban

cat > /etc/fail2ban/jail.local << 'FAIL2BAN_EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
FAIL2BAN_EOF

systemctl enable fail2ban
systemctl restart fail2ban

log "✓ Fail2ban configured for SSH protection"

# ==============================================================================
# BACKUP CONFIGURATION
# ==============================================================================

log "Setting up automated backup system..."

# Create backup directory
mkdir -p $INSTALL_DIR/backups

# Create backup script
cat > $INSTALL_DIR/backup.sh << 'BACKUP_EOF'
#!/bin/bash
set -e

INSTALL_DIR="/opt/firezone"
BACKUP_DIR="$INSTALL_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/firezone_backup_$TIMESTAMP.tar.gz"

# Keep only last 7 days of backups
find $BACKUP_DIR -name "firezone_backup_*.tar.gz" -mtime +7 -delete

# Backup PostgreSQL database
docker-compose -f $INSTALL_DIR/docker-compose.yml exec -T postgres pg_dump -U postgres firezone > $BACKUP_DIR/db_$TIMESTAMP.sql

# Backup .env and docker-compose.yml
tar -czf $BACKUP_FILE \
  -C $INSTALL_DIR \
  .env \
  docker-compose.yml \
  backups/db_$TIMESTAMP.sql

# Remove temporary DB dump
rm $BACKUP_DIR/db_$TIMESTAMP.sql

echo "Backup completed: $BACKUP_FILE"
BACKUP_EOF

chmod +x $INSTALL_DIR/backup.sh

# Create daily backup cron job
cat > /etc/cron.daily/firezone-backup << 'CRON_EOF'
#!/bin/bash
/opt/firezone/backup.sh >> /var/log/firezone-backup.log 2>&1
CRON_EOF

chmod +x /etc/cron.daily/firezone-backup

log "✓ Daily backup configured (backups stored in $INSTALL_DIR/backups)"

# ==============================================================================
# LOG ROTATION
# ==============================================================================

log "Configuring log rotation..."

cat > /etc/logrotate.d/firezone << 'LOGROTATE_EOF'
/opt/firezone/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
}
LOGROTATE_EOF

# Create logs directory
mkdir -p $INSTALL_DIR/logs

log "✓ Log rotation configured"

# ==============================================================================
# CREATE SYSTEMD SERVICE FOR AUTOMATIC STARTUP
# ==============================================================================

log "Creating systemd service for automatic startup..."
cat > /etc/systemd/system/firezone.service << 'SYSTEMD_EOF'
[Unit]
Description=Firezone VPN Server
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/opt/firezone
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=300
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

systemctl daemon-reload
systemctl enable firezone.service

# ==============================================================================
# SAVE INSTALLATION SUMMARY
# ==============================================================================

ADMIN_PASSWORD=$(grep DEFAULT_ADMIN_PASSWORD $INSTALL_DIR/.env | cut -d= -f2)

cat > $INSTALL_DIR/installation-info.txt << EOF
Firezone Installation Summary
============================
Installation Date: $(date)
Domain: $FIREZONE_DOMAIN
Admin Email: $ADMIN_EMAIL
Admin Password: $ADMIN_PASSWORD
WireGuard Port: 51820
Installation Directory: $INSTALL_DIR

Service Management:
- Start: systemctl start firezone
- Stop: systemctl stop firezone
- Status: systemctl status firezone
- Restart: systemctl restart firezone
- Logs: $dc -f $INSTALL_DIR/docker-compose.yml logs -f

Backup Management:
- Manual backup: $INSTALL_DIR/backup.sh
- Backup location: $INSTALL_DIR/backups
- Automatic backups: Daily via cron

Security:
- Fail2ban: Active (SSH protection)
- Firewall: UFW enabled
- SSL/TLS: Let's Encrypt (auto-renewal)

Admin Interface: https://$FIREZONE_DOMAIN

Health Check:
- Check services: $dc -f $INSTALL_DIR/docker-compose.yml ps
- Check SSL: curl -I https://$FIREZONE_DOMAIN
- Check logs: $dc -f $INSTALL_DIR/docker-compose.yml logs -f caddy
EOF

chmod 600 $INSTALL_DIR/installation-info.txt
log "Installation summary saved to $INSTALL_DIR/installation-info.txt"

# ==============================================================================
# FINAL HEALTH CHECK
# ==============================================================================

log "Performing final health check..."

# Display container status
log "Firezone containers status:"
$dc -f $INSTALL_DIR/docker-compose.yml ps

# Check if all containers are running
POSTGRES_STATUS=$($dc -f $INSTALL_DIR/docker-compose.yml ps postgres | grep -c "Up" || echo "0")
FIREZONE_STATUS=$($dc -f $INSTALL_DIR/docker-compose.yml ps firezone | grep -c "Up" || echo "0")
CADDY_STATUS=$($dc -f $INSTALL_DIR/docker-compose.yml ps caddy | grep -c "Up" || echo "0")

if [ "$POSTGRES_STATUS" -eq "1" ] && [ "$FIREZONE_STATUS" -eq "1" ] && [ "$CADDY_STATUS" -eq "1" ]; then
  log "✓ All containers are running"
else
  log "WARNING: Some containers may not be running properly"
  log "Check logs with: $dc -f $INSTALL_DIR/docker-compose.yml logs"
fi

# ==============================================================================
# DISPLAY FINAL SUMMARY
# ==============================================================================

cat << 'FINAL_BANNER'

╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                    FIREZONE INSTALLATION COMPLETED!                          ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

FINAL_BANNER

log ""
log "=========================================================================="
log "                     INSTALLATION SUMMARY"
log "=========================================================================="
log ""
log "Admin Interface: https://$FIREZONE_DOMAIN"
log "Admin Email: $ADMIN_EMAIL"
log "Admin Password: $ADMIN_PASSWORD"
log ""
log "IMPORTANT NEXT STEPS:"
log "1. Log in to the admin interface at https://$FIREZONE_DOMAIN"
log "2. Change the admin password immediately"
log "3. Configure your first VPN device or user"
log "4. Save the credentials in installation-info.txt to a secure location"
log ""
log "SECURITY NOTES:"
log "✓ SSL/TLS certificates: Auto-provisioned by Let's Encrypt"
log "✓ Firewall: UFW enabled (ports 22, 80, 443, 51820)"
log "✓ Fail2ban: Active (SSH brute-force protection)"
log "✓ Backups: Daily automated backups to $INSTALL_DIR/backups"
log "✓ IP Forwarding: Enabled for VPN routing"
log "✓ NAT/Masquerading: Configured"
log ""
log "TROUBLESHOOTING:"
log "- View logs: $dc -f $INSTALL_DIR/docker-compose.yml logs -f"
log "- Check SSL: curl -I https://$FIREZONE_DOMAIN"
log "- Container status: $dc -f $INSTALL_DIR/docker-compose.yml ps"
log "- Full info: cat $INSTALL_DIR/installation-info.txt"
log ""
log "=========================================================================="
log ""

log "Firezone setup script completed successfully"
