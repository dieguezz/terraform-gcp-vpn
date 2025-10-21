# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial repository setup
- Core Terraform modules (network, compute, security, load-balancer, vpn-gateway, scheduler)
- Example configurations (minimal, with-scheduler, site-to-site)
- CI/CD workflows (pre-commit, GitHub Actions)
- Documentation (README, module READMEs, architecture diagrams)
- Makefile utilities (ssh, logs, instance-status, vpn-tunnel-status)
- Security hardening (shielded VM, OS Login, IAP, CMEK support)
- Site-to-site IPsec tunnel support (Classic Cloud VPN)
- Auto start/stop scheduling (Cloud Scheduler + Cloud Functions)
- Marketing assets (banner, social media templates)

### Changed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- Implemented least-privilege IAM policies
- Secrets stored in Secret Manager (not in Terraform state)
- Explicit egress firewall rules
- VPC Flow Logs enabled by default

---

## How to Use This Changelog

### For Maintainers

When releasing a new version:

1. Move items from `[Unreleased]` to a new version section
2. Add the release date in YYYY-MM-DD format
3. Create a Git tag matching the version
4. Update links at the bottom of this file

### Version Format

- **MAJOR:** Breaking changes (e.g., 2.0.0)
- **MINOR:** New features, backward-compatible (e.g., 1.1.0)
- **PATCH:** Bug fixes, backward-compatible (e.g., 1.0.1)

### Section Guidelines

- **Added:** New features
- **Changed:** Changes in existing functionality
- **Deprecated:** Soon-to-be removed features
- **Removed:** Removed features
- **Fixed:** Bug fixes
- **Security:** Security improvements

---

## Release History

### [1.0.0] - TBD

Initial stable release.

---

[Unreleased]: https://github.com/dieguezz/terraform-gcp-vpn/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/dieguezz/terraform-gcp-vpn/releases/tag/v1.0.0
