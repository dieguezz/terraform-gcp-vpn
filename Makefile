.PHONY: help ssh credentials logs start-instance stop-instance instance-status vpn-logs vpn-tunnel-status

PARTNER ?=
SITE_TO_SITE_DIR := scripts/site-to-site

# Default target
help:
	@echo "📚 VPN Site-to-Site - Utility Commands"
	@echo ""
	@echo "🔥 Firezone Management"
	@echo "  make ssh              - SSH into Firezone instance"
	@echo "  make credentials      - Get admin credentials"
	@echo "  make logs             - View Firezone logs (live)"
	@echo "  make start-instance   - Start Firezone instance"
	@echo "  make stop-instance    - Stop Firezone instance"
	@echo "  make instance-status  - Check instance status"
	@echo ""
	@echo " 🌐 Site-to-Site VPN (IPsec Tunnel)"
	@echo "  make vpn-tunnel-status PARTNER=<name> - Display tunnel status"
	@echo "  make vpn-logs                        - View VPN tunnel logs"
	@echo ""
	@echo "💻 Terraform Commands"
	@echo "  terraform init        - Initialize Terraform"
	@echo "  terraform plan        - Review planned changes"
	@echo "  terraform apply       - Apply infrastructure changes"
	@echo ""

# Site-to-Site VPN utilities
vpn-tunnel-status:
	@if [ -z "$(PARTNER)" ]; then \
		echo "❌ Specify the partner folder via PARTNER=<name>."; \
		echo "   Available partners:"; \
		if [ -d "$(SITE_TO_SITE_DIR)" ]; then \
		for dir in $(SITE_TO_SITE_DIR)/*; do \
		  if [ -d "$$dir" ] && [ "$$(basename "$$dir")" != "common" ]; then \
		    echo "     - $$(basename "$$dir")"; \
		  fi; \
		done; \
		else \
		  echo "     (none found)"; \
		fi; \
		echo ""; \
		exit 1; \
	fi; \
	SCRIPT="$(SITE_TO_SITE_DIR)/$(PARTNER)/verify-tunnel.sh"; \
	if [ ! -f "$$SCRIPT" ]; then \
		echo "❌ Partner script not found at $$SCRIPT"; \
		exit 1; \
	fi; \
	PARTNER_NAME="$(PARTNER)" bash "$$SCRIPT"

# Firezone Management Commands
ssh:
	@INSTANCE=$$(terraform output -raw instance_name 2>/dev/null) && \
	ZONE=$$(terraform output -raw instance_zone 2>/dev/null) && \
	if [ -z "$$INSTANCE" ] || [ -z "$$ZONE" ]; then \
		echo "❌ Error: Run 'terraform apply' first to initialize outputs"; \
		exit 1; \
	fi && \
	STATUS=$$(gcloud compute instances describe $$INSTANCE --zone=$$ZONE --format='value(status)' 2>/dev/null) && \
	if [ "$$STATUS" != "RUNNING" ]; then \
		echo "⏸️  Instance is $$STATUS. Start it with: gcloud compute instances start $$INSTANCE --zone=$$ZONE"; \
		echo "🕒 Or wait for Cloud Scheduler (Mon-Fri 7:00 AM)"; \
		exit 1; \
	fi && \
	gcloud compute ssh $$INSTANCE --zone=$$ZONE --tunnel-through-iap

credentials:
	@INSTANCE=$$(terraform output -raw instance_name 2>/dev/null) && \
	ZONE=$$(terraform output -raw instance_zone 2>/dev/null) && \
	if [ -z "$$INSTANCE" ] || [ -z "$$ZONE" ]; then \
		echo "❌ Error: Run 'terraform apply' first to initialize outputs"; \
		exit 1; \
	fi && \
	STATUS=$$(gcloud compute instances describe $$INSTANCE --zone=$$ZONE --format='value(status)' 2>/dev/null) && \
	if [ "$$STATUS" != "RUNNING" ]; then \
		echo "⏸️  Instance is $$STATUS. Start it with: gcloud compute instances start $$INSTANCE --zone=$$ZONE"; \
		echo "🕒 Or wait for Cloud Scheduler (Mon-Fri 7:00 AM)"; \
		exit 1; \
	fi && \
	gcloud compute ssh $$INSTANCE --zone=$$ZONE --tunnel-through-iap --command='sudo docker exec firezone-firezone-1 /bin/sh -c "bin/gen-env-file | grep DEFAULT_ADMIN"'

logs:
	@INSTANCE=$$(terraform output -raw instance_name 2>/dev/null) && \
	ZONE=$$(terraform output -raw instance_zone 2>/dev/null) && \
	if [ -z "$$INSTANCE" ] || [ -z "$$ZONE" ]; then \
		echo "❌ Error: Run 'terraform apply' first to initialize outputs"; \
		exit 1; \
	fi && \
	STATUS=$$(gcloud compute instances describe $$INSTANCE --zone=$$ZONE --format='value(status)' 2>/dev/null) && \
	if [ "$$STATUS" != "RUNNING" ]; then \
		echo "⏸️  Instance is $$STATUS. Start it with: gcloud compute instances start $$INSTANCE --zone=$$ZONE"; \
		echo "🕒 Or wait for Cloud Scheduler (Mon-Fri 7:00 AM)"; \
		exit 1; \
	fi && \
	gcloud compute ssh $$INSTANCE --zone=$$ZONE --tunnel-through-iap --command='sudo docker-compose logs -f firezone'

# Instance Management Commands
start-instance:
	@INSTANCE=$$(terraform output -raw instance_name 2>/dev/null) && \
	ZONE=$$(terraform output -raw instance_zone 2>/dev/null) && \
	if [ -z "$$INSTANCE" ] || [ -z "$$ZONE" ]; then \
		echo "❌ Error: Run 'terraform apply' first to initialize outputs"; \
		exit 1; \
	fi && \
	echo "▶️  Starting $$INSTANCE..." && \
	gcloud compute instances start $$INSTANCE --zone=$$ZONE && \
	echo "✅ Instance started successfully"

stop-instance:
	@INSTANCE=$$(terraform output -raw instance_name 2>/dev/null) && \
	ZONE=$$(terraform output -raw instance_zone 2>/dev/null) && \
	if [ -z "$$INSTANCE" ] || [ -z "$$ZONE" ]; then \
		echo "❌ Error: Run 'terraform apply' first to initialize outputs"; \
		exit 1; \
	fi && \
	echo "⏹️  Stopping $$INSTANCE..." && \
	gcloud compute instances stop $$INSTANCE --zone=$$ZONE && \
	echo "✅ Instance stopped successfully"

instance-status:
	@INSTANCE=$$(terraform output -raw instance_name 2>/dev/null) && \
	ZONE=$$(terraform output -raw instance_zone 2>/dev/null) && \
	if [ -z "$$INSTANCE" ] || [ -z "$$ZONE" ]; then \
		echo "❌ Error: Run 'terraform apply' first to initialize outputs"; \
		exit 1; \
	fi && \
	STATUS=$$(gcloud compute instances describe $$INSTANCE --zone=$$ZONE --format='value(status)' 2>/dev/null) && \
	if [ "$$STATUS" = "RUNNING" ]; then \
		echo "✅ Instance is $$STATUS"; \
	elif [ "$$STATUS" = "SUSPENDED" ]; then \
		echo "⏸️  Instance is $$STATUS"; \
	elif [ "$$STATUS" = "TERMINATED" ]; then \
		echo "⏹️  Instance is $$STATUS"; \
	else \
		echo "🔄 Instance is $$STATUS"; \
	fi

# VPN Tunnel Logs
vpn-logs:
	@echo "📜 Fetching VPN tunnel logs (last 50 entries)..."
	@gcloud logging read "resource.type=vpn_tunnel" \
		--limit=50 \
		--format="table(timestamp,resource.labels.tunnel_name,jsonPayload.message)"
