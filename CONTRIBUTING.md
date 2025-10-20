# Contributing

Thanks for your interest in improving this project! To keep things smooth we
ask everyone to follow the guidelines below.

## Getting Started
- Fork the repository and create a feature branch off `main`.
- Run `terraform fmt -recursive` and keep diffs focused on the change you are
  proposing.
- Update documentation or examples when behaviour changes.

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
