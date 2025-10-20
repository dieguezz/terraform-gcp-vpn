# Contributing

Thanks for your interest in improving this project! To keep things smooth we
ask everyone to follow the guidelines below.

## Getting Started
- Fork the repository and create a feature branch off `main`.
- Run `terraform fmt -recursive` and keep diffs focused on the change you are
  proposing.
- Update documentation or examples when behaviour changes.

## Local Tooling Setup

Install required CLI tools (macOS example):

```bash
brew install terraform tflint trivy terraform-docs pre-commit
pip install --upgrade pre-commit
```

Initialize pre-commit hooks:

```bash
pre-commit install
pre-commit run --all-files

### Verify Tooling

```bash
terraform version
tflint --version
trivy --version
terraform-docs --version
```

If any binary is missing, (macOS/Homebrew) reinstall:

```bash
brew reinstall terraform tflint trivy terraform-docs
```
```

If hooks complain:
1. Clear cache `rm -rf ~/.cache/pre-commit`.
2. Update hooks `pre-commit autoupdate`.
3. Re-run `pre-commit run --all-files`.

### Regenerating Documentation

The `terraform_docs` hook keeps Inputs/Outputs sections current. After changing variables or outputs:

```bash
pre-commit run terraform_docs --all-files
git add README.md examples/*/README.md
```

### Security & Linting

- `tflint` enforces style and provider best-practices.
- `trivy` IaC scanning replaces deprecated `tfsec` (soft-fail initially if needed).
- Add inline ignore only with justification (example for tflint): `# tflint-ignore: RULE`.

### Optional Extras

For deeper scans run manually:

```bash
trivy config .
tflint --recursive
```

## Commit Style
- Use concise commit messages in the imperative voice (for example: `Add vpn
  tunnel verifier`).
- Reference GitHub issues when relevant (`Fixes #123`).

## Pull Requests
- Fill in the pull request template with context, testing steps, and any known
  trade-offs.
- Ensure CI (formatting, terraform validate, shellcheck) passes.
- If your change alters infrastructure defaults, explain the migration steps in
  the PR description.

## Code of Conduct
This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). Instances of
abusive, harassing, or otherwise unacceptable behaviour may be reported to
diego@etereo.io.

## Security
If you discover a security issue, please email diego@etereo.io instead of
opening a public issue.
