# Security Policy

## Supported Versions

Only the latest released chart version is actively supported with security
updates. Older chart versions may receive fixes at the maintainers' discretion.

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| Older   | :x:                |

## Reporting a Vulnerability

If you believe you have found a security vulnerability in this Helm chart,
**please do not open a public GitHub issue**.

Instead, report it privately using GitHub's
[Private Vulnerability Reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
feature on this repository, or by opening a draft security advisory under the
**Security** tab.

When reporting, please include:

- A description of the vulnerability and its potential impact.
- Steps to reproduce the issue (chart version, values used, Kubernetes version).
- Any relevant logs, manifests, or proof-of-concept output.

You should expect an initial response within a few business days. We will work
with you to confirm the issue, develop a fix, and coordinate disclosure.

## Scope

This policy covers issues in the Helm chart contained in this repository
(templates, default values, and packaging). Vulnerabilities in upstream
Technitium DNS Server itself should be reported to the
[Technitium project](https://github.com/TechnitiumSoftware/DnsServer).
