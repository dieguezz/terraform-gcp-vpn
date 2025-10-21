# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within this project, please send an email to **security@yourdomain.com** (or create a private security advisory on GitHub).

**Please do not report security vulnerabilities through public GitHub issues.**

### What to include in your report:

- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact
- Suggested fix (if any)

### Response timeline:

- **Initial response:** Within 48 hours
- **Status update:** Within 7 days
- **Fix timeline:** Depends on severity (critical issues within 72 hours)

## Security Best Practices

When deploying this Terraform module, follow these security recommendations:

### Infrastructure Security

1. **Least Privilege IAM**
   - Use dedicated service accounts with minimal permissions
   - Enable IAM conditions where applicable
   - Review `modules/security/` for baseline policies

2. **Secrets Management**
   - Store all sensitive data in Secret Manager
   - Never commit credentials to version control
   - Rotate secrets regularly (PSKs, admin credentials)

3. **Network Security**
   - Review firewall rules in `modules/security/`
   - Restrict source IP ranges where possible
   - Enable VPC Flow Logs for audit trails

4. **VM Hardening**
   - Use shielded VMs (enabled by default)
   - Enable OS Login and disable password authentication
   - Access instances only via Identity-Aware Proxy (IAP)
   - Keep OS and Firezone software updated

5. **Encryption**
   - Enable CMEK for boot disks (optional, see variables)
   - Use TLS for all external traffic
   - Encrypt IPsec tunnels with strong ciphers (AES-256, SHA-256)

### Operational Security

1. **Monitoring & Alerting**
   - Enable Cloud Logging and Monitoring
   - Set up alerts for unusual traffic patterns
   - Monitor VPN tunnel status and uptime

2. **Access Control**
   - Use Google Workspace SSO for Firezone authentication
   - Implement MFA for administrative access
   - Regularly audit user access logs

3. **Backup & Recovery**
   - Back up Terraform state to GCS with versioning enabled
   - Document disaster recovery procedures
   - Test restore procedures periodically

4. **Dependency Management**
   - Keep Terraform and providers up to date
   - Review security advisories for dependencies
   - Use Dependabot or similar tools for automated updates

## Known Limitations

- Classic Cloud VPN does not support automatic IKE rekeying; monitor tunnel health
- Single-instance deployment (no HA by default)
- Scheduler automation requires Cloud Functions with network access

## Compliance Considerations

This module does not enforce specific compliance frameworks (PCI-DSS, HIPAA, etc.). If you need compliance:

- Review your organization's security requirements
- Conduct a security assessment before production deployment
- Implement additional controls as needed (e.g., CMEK, private endpoints)

## Third-Party Security

This project integrates with:

- **Firezone:** Review [Firezone security documentation](https://www.firezone.dev/docs/reference/security)
- **Google Cloud Platform:** Follow [GCP security best practices](https://cloud.google.com/security/best-practices)

## Security Updates

Security patches will be released as:

- **Patch releases** (e.g., 1.0.1) for minor fixes
- **Minor releases** (e.g., 1.1.0) for larger security improvements
- **Immediate advisories** for critical vulnerabilities

Subscribe to repository releases to stay informed.

---

**Last updated:** 2025-10-21
