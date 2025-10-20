---
name: Bug Report
about: Create a report to help us improve
title: "bug: <short description>"
labels: [bug]
assignees: []
---

## Description
A clear and concise description of the problem.

## Terraform / Provider Versions
```
terraform version
```
Provider versions from `.terraform.lock.hcl` or `terraform providers`.

## Module Configuration (Minimal Repro)
```hcl
# Paste only the relevant module invocation and variables
```

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened (include error output / logs).

## Steps to Reproduce
1. Go to '...'
2. Run 'terraform ...'
3. See error

## Diagnostics
- Output of `terraform validate`:
- Output of `tflint --recursive` (if relevant):
- Output of `tfsec .` (if relevant):

## Additional Context
Add any other context or screenshots.
